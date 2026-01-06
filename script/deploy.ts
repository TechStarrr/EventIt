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
