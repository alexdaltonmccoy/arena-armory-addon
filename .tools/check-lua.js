// Syntax-check all addon Lua files as Lua 5.1.
const fs = require("fs");
const path = require("path");
const luaparse = require("luaparse");

const root = path.join(__dirname, "..", "ArenaArmory");
let failures = 0;

function walk(dir) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (entry.name === "Libs") continue; // third-party, trusted
      walk(full);
    } else if (entry.name.endsWith(".lua")) {
      const src = fs.readFileSync(full, "utf8");
      try {
        luaparse.parse(src, { luaVersion: "5.1" });
        console.log("OK   " + path.relative(root, full));
      } catch (e) {
        failures++;
        console.log("FAIL " + path.relative(root, full) + " :: " + e.message);
      }
    }
  }
}

walk(root);
process.exit(failures ? 1 : 0);
