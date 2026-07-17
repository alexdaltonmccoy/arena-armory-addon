// One-off diagnostic: how many stored matches carry ratings data, and what
// the most recent records look like. Run: node .tools/inspect-ratings.js
const fs = require("fs");

const file =
  "C:/Program Files (x86)/World of Warcraft/_anniversary_/WTF/Account/KAETOS/SavedVariables/ArenaArmory.lua";
const src = fs.readFileSync(file, "utf8");

const matchCount = (src.match(/\["guid"\]/g) || []).length;
const ratingsCount = (src.match(/\["ratings"\]/g) || []).length;
console.log("stored matches:", matchCount, "| with ratings key:", ratingsCount);
console.log("file mtime:", fs.statSync(file).mtime.toLocaleString());

const times = [...src.matchAll(/\["startedAt"\] = (\d+)/g)].map((m) =>
  Number(m[1])
);
times.sort((a, b) => a - b);
console.log(
  "latest 5 match times:",
  times.slice(-5).map((t) => new Date(t * 1000).toLocaleString())
);

const idx = src.lastIndexOf('["ratings"]');
if (idx >= 0) {
  console.log("--- last ratings block ---");
  console.log(src.slice(idx, idx + 500));
}
