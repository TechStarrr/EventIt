import "dotenv/config";
import fs from "node:fs";
import path from "node:path";

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
