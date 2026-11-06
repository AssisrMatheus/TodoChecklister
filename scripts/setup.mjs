// Fetches dev-only tooling that is not committed:
//  - WoW API annotations (Ketho/vscode-wow-api) into .annotations/wow-api
//  - emmylua_check binary (GitHub release) into .tools/
import { execFileSync } from "node:child_process";
import { existsSync, mkdirSync, rmSync } from "node:fs";
import { join } from "node:path";

const root = new URL("..", import.meta.url).pathname;
const run = (cmd, args, opts = {}) => execFileSync(cmd, args, { stdio: "inherit", ...opts });

// 1. WoW API annotations (sparse, shallow clone of only the Annotations folder)
const annotations = join(root, ".annotations", "wow-api");
if (existsSync(join(annotations, ".git"))) {
  run("git", ["-C", annotations, "pull", "--depth", "1", "--ff-only"]);
} else {
  rmSync(annotations, { recursive: true, force: true });
  mkdirSync(join(root, ".annotations"), { recursive: true });
  run("git", ["clone", "--depth", "1", "--filter=blob:none", "--sparse",
    "https://github.com/Ketho/vscode-wow-api.git", annotations]);
  run("git", ["-C", annotations, "sparse-checkout", "set", "Annotations"]);
}

// 2. emmylua_check (CLI diagnostics, same engine as emmylua_ls)
const platform = { darwin: "darwin", linux: "linux", win32: "win32" }[process.platform];
const arch = { arm64: process.platform === "linux" ? "aarch64-glibc.2.17" : "arm64", x64: "x64" }[process.arch];
const tools = join(root, ".tools");
mkdirSync(tools, { recursive: true });
const ext = platform === "win32" ? "zip" : "tar.gz";
const asset = `emmylua_check-${platform}-${arch}.${ext}`;
const url = `https://github.com/EmmyLuaLs/emmylua-analyzer-rust/releases/latest/download/${asset}`;
const archive = join(tools, asset);
run("curl", ["-fsSL", "-o", archive, url]);
run("tar", ["-xf", archive, "-C", tools]);
rmSync(archive);
console.log("\nDone. Language server: install with `brew install emmylua_ls` (or `cargo install emmylua_ls`).");
