// Quick scan of the ArenaArmory SavedVariables: match count, latest matches,
// and the team roster of the newest games (debugging missing partner/match).
const fs = require("fs");
const path =
  "C:\\Program Files (x86)\\World of Warcraft\\_anniversary_\\WTF\\Account\\KAETOS\\SavedVariables\\ArenaArmory.lua";
const src = fs.readFileSync(path, "utf8");

// Split into per-match blocks on top-level match entries.
const re = /\["startedAt"\] = (\d+)/g;
let m;
const ts = [];
while ((m = re.exec(src))) ts.push(Number(m[1]));
console.log("total matches in file:", ts.length);
ts.sort((a, b) => b - a);
for (const t of ts.slice(0, 8)) console.log("  ", new Date(t * 1000).toLocaleString());

// Show the raw block around the newest match for roster inspection.
const newest = Math.max(...ts);
const idx = src.indexOf(`["startedAt"] = ${newest}`);
console.log("\n--- newest match block (excerpt) ---");
console.log(src.slice(Math.max(0, idx - 2000), idx + 2500));
