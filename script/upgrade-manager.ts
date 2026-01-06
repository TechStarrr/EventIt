import "dotenv/config";
import fs from "node:fs";
import path from "node:path";
import { createPublicClient, createWalletClient, http } from "viem";
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
  const proxyAddress = getEnv("MANAGER_PROXY") as `0x${string}`;
  const chain = chainId === base.id ? base : baseSepolia;

  const account = privateKeyToAccount(privateKey);
  const publicClient = createPublicClient({ chain, transport: http(rpcUrl) });
  const walletClient = createWalletClient({ account, chain, transport: http(rpcUrl) });

  const v2Artifact = loadArtifact("EventItEventManagerV2");
  const v2ImplHash = await walletClient.deployContract({
    abi: v2Artifact.abi,
    bytecode: normalizeBytecode(v2Artifact.bytecode),
  });
  const v2Impl = await publicClient.waitForTransactionReceipt({ hash: v2ImplHash });

  await walletClient.writeContract({
    address: proxyAddress,
    abi: v2Artifact.abi,
    functionName: "upgradeToAndCall",
    args: [v2Impl.contractAddress, "0x"],
  });

  console.log("EventManager V2 implementation:", v2Impl.contractAddress);
  console.log("EventManager proxy upgraded:", proxyAddress);
}

void main();
