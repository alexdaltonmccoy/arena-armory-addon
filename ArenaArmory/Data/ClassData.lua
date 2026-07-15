-- Class tokens, colors, and test-mode sample data (TBC: no Death Knight+).
local _, AA = ...

AA.CLASSES = {
    "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST",
    "SHAMAN", "MAGE", "WARLOCK", "DRUID",
}

function AA.ClassColor(classToken)
    local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken]
    if c then return c.r, c.g, c.b end
    return 0.6, 0.6, 0.6
end

-- Coordinates into Interface\Glues\CharacterCreate\UI-CharacterCreate-Classes
AA.CLASS_ICON_TCOORDS = CLASS_ICON_TCOORDS or {
    WARRIOR = { 0, 0.25, 0, 0.25 },
    MAGE    = { 0.25, 0.49609375, 0, 0.25 },
    ROGUE   = { 0.49609375, 0.7421875, 0, 0.25 },
    DRUID   = { 0.7421875, 0.98828125, 0, 0.25 },
    HUNTER  = { 0, 0.25, 0.25, 0.5 },
    SHAMAN  = { 0.25, 0.49609375, 0.25, 0.5 },
    PRIEST  = { 0.49609375, 0.7421875, 0.25, 0.5 },
    WARLOCK = { 0.7421875, 0.98828125, 0.25, 0.5 },
    PALADIN = { 0, 0.25, 0.5, 0.75 },
}

AA.POWER_COLORS = {
    MANA = { 0.25, 0.5, 1 },
    RAGE = { 1, 0.2, 0.2 },
    ENERGY = { 1, 0.9, 0.3 },
    FOCUS = { 1, 0.5, 0.25 },
}

AA.CLASS_DEFAULT_POWER = {
    WARRIOR = "RAGE", ROGUE = "ENERGY",
    PALADIN = "MANA", HUNTER = "MANA", PRIEST = "MANA",
    SHAMAN = "MANA", MAGE = "MANA", WARLOCK = "MANA", DRUID = "MANA",
}

-- Test mode sample opponents.
AA.TEST_OPPONENTS = {
    { name = "Testrogue",   class = "ROGUE",   spec = "Subtlety",    health = 0.85, power = 0.6,  powerType = "ENERGY" },
    { name = "Testpriest",  class = "PRIEST",  spec = "Discipline",  health = 0.62, power = 0.45, powerType = "MANA" },
    { name = "Testmage",    class = "MAGE",    spec = "Frost",       health = 1.0,  power = 0.9,  powerType = "MANA" },
    { name = "Testwarrior", class = "WARRIOR", spec = "Arms",        health = 0.35, power = 0.8,  powerType = "RAGE" },
    { name = "Testdruid",   class = "DRUID",   spec = "Restoration", health = 0.5,  power = 0.3,  powerType = "MANA" },
}
