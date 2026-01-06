import "dotenv/config";
import fs from "node:fs";
import path from "node:path";
import { createPublicClient, createWalletClient, encodeFunctionData, http } from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { base, baseSepolia } from "viem/chains";

type Artifact = {
  abi: unknown;
  bytecode: { object: string } | string;
};

function loadArtifact(contractName: string): Artifact {
  const artifactPath = path.join(
    process.cwd(),
    "out",
    `${contractName}.sol`,
    `${contractName}.json`
  );
  const raw = fs.readFileSync(artifactPath, "utf8");
  return JSON.parse(raw) as Artifact;
}

function normalizeBytecode(bytecode: Artifact["bytecode"]): `0x${string}` {
  const raw = typeof bytecode === "string" ? bytecode : bytecode.object;
  return raw.startsWith("0x") ? (raw as `0x${string}`) : (`0x${raw}` as `0x${string}`);
}

function getEnv(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing env var: ${name}`);
  }
  return value;
}

async function main() {
  const rpcUrl = getEnv("RPC_URL");
  const privateKey = getEnv("PRIVATE_KEY") as `0x${string}`;
  const chainId = Number(getEnv("CHAIN_ID"));
  const chain = chainId === base.id ? base : baseSepolia;

  const account = privateKeyToAccount(privateKey);
  const publicClient = createPublicClient({ chain, transport: http(rpcUrl) });
  const walletClient = createWalletClient({ account, chain, transport: http(rpcUrl) });

  const proxyArtifact = loadArtifact("ERC1967Proxy");
  const ticketArtifact = loadArtifact("EventItTicket");
  const managerArtifact = loadArtifact("EventItEventManager");
  const checkInArtifact = loadArtifact("EventItCheckIn");

  const ticketImplHash = await walletClient.deployContract({
    abi: ticketArtifact.abi,
    bytecode: normalizeBytecode(ticketArtifact.bytecode),
  });
  const ticketImpl = await publicClient.waitForTransactionReceipt({ hash: ticketImplHash });

  const managerImplHash = await walletClient.deployContract({
    abi: managerArtifact.abi,
    bytecode: normalizeBytecode(managerArtifact.bytecode),
  });
  const managerImpl = await publicClient.waitForTransactionReceipt({ hash: managerImplHash });

  const checkInImplHash = await walletClient.deployContract({
    abi: checkInArtifact.abi,
    bytecode: normalizeBytecode(checkInArtifact.bytecode),
  });
  const checkInImpl = await publicClient.waitForTransactionReceipt({ hash: checkInImplHash });

  const ticketInit = encodeFunctionData({
    abi: ticketArtifact.abi,
    functionName: "initialize",
    args: ["EventIt Ticket", "EVT", account.address],
  });

  const ticketProxyHash = await walletClient.deployContract({
    abi: proxyArtifact.abi,
    bytecode: normalizeBytecode(proxyArtifact.bytecode),
    args: [ticketImpl.contractAddress, ticketInit],
  });
  const ticketProxy = await publicClient.waitForTransactionReceipt({ hash: ticketProxyHash });

  const managerInit = encodeFunctionData({
    abi: managerArtifact.abi,
    functionName: "initialize",
    args: [ticketProxy.contractAddress],
  });

  const managerProxyHash = await walletClient.deployContract({
    abi: proxyArtifact.abi,
    bytecode: normalizeBytecode(proxyArtifact.bytecode),
    args: [managerImpl.contractAddress, managerInit],
  });
  const managerProxy = await publicClient.waitForTransactionReceipt({ hash: managerProxyHash });

  const checkInInit = encodeFunctionData({
    abi: checkInArtifact.abi,
    functionName: "initialize",
    args: [ticketProxy.contractAddress, managerProxy.contractAddress],
  });

  const checkInProxyHash = await walletClient.deployContract({
    abi: proxyArtifact.abi,
    bytecode: normalizeBytecode(proxyArtifact.bytecode),
    args: [checkInImpl.contractAddress, checkInInit],
  });
  const checkInProxy = await publicClient.waitForTransactionReceipt({ hash: checkInProxyHash });

  await walletClient.writeContract({
    address: ticketProxy.contractAddress,
    abi: ticketArtifact.abi,
    functionName: "setEventManager",
    args: [managerProxy.contractAddress],
  });

  await walletClient.writeContract({
    address: ticketProxy.contractAddress,
    abi: ticketArtifact.abi,
    functionName: "setCheckIn",
    args: [checkInProxy.contractAddress],
  });

  console.log("Ticket implementation:", ticketImpl.contractAddress);
  console.log("EventManager implementation:", managerImpl.contractAddress);
  console.log("CheckIn implementation:", checkInImpl.contractAddress);
  console.log("Ticket proxy:", ticketProxy.contractAddress);
  console.log("EventManager proxy:", managerProxy.contractAddress);
  console.log("CheckIn proxy:", checkInProxy.contractAddress);
}

void main();
