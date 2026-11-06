// Clones/updates Blizzard UI source (Gethe/wow-ui-source) per game flavor into ./vendor (gitignored).
// Reference only: not loaded by the addon, not indexed by the language server.
import { execFileSync } from "node:child_process";
import { existsSync, mkdirSync } from "node:fs";
import { join } from "node:path";

const REPO = "https://github.com/Gethe/wow-ui-source.git";
const FLAVORS = {
  retail: "live", //               The War Within / Midnight (12.x)
  classic: "classic", //           Progression Classic (5.x, Mists)
  classic_era: "classic_era", //   Classic Era / Hardcore (1.15.x)
  anniversary: "classic_anniversary", // Anniversary realms (2.5.x, TBC)
  forever: "forever", //           WoW: Forever (1.60.x content on the retail client/UI)
};

const root = new URL("..", import.meta.url).pathname;
const vendor = join(root, "vendor");
mkdirSync(vendor, { recursive: true });
const git = (args) => execFileSync("git", args, { stdio: "inherit" });

const only = process.argv.slice(2);
for (const [dir, branch] of Object.entries(FLAVORS)) {
  if (only.length && !only.includes(dir)) continue;
  const target = join(vendor, dir);
  if (existsSync(join(target, ".git"))) {
    git(["-C", target, "fetch", "--depth", "1", "origin", branch]);
    git(["-C", target, "reset", "--hard", "FETCH_HEAD"]);
  } else {
    git(["clone", "--depth", "1", "--single-branch", "-b", branch, REPO, target]);
  }
  execFileSync("git", ["-C", target, "log", "-1", "--format=" + dir + ": %s"], { stdio: "inherit" });
}
