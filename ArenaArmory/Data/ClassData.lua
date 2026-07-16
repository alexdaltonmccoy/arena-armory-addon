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

-- TBC talent-tree icons for the stats panel's team strips. Keys match the
-- spec names produced by SpecDetection (enemies) and GetTalentTabInfo (the
-- player), including the "Feral Combat" tab-name variant.
AA.SPEC_ICONS = {
    WARRIOR = {
        ["Arms"] = "Interface\\Icons\\Ability_Warrior_SavageBlow",
        ["Fury"] = "Interface\\Icons\\Ability_Warrior_InnerRage",
        ["Protection"] = "Interface\\Icons\\Ability_Warrior_DefensiveStance",
    },
    PALADIN = {
        ["Holy"] = "Interface\\Icons\\Spell_Holy_HolyBolt",
        ["Protection"] = "Interface\\Icons\\Spell_Holy_DevotionAura",
        ["Retribution"] = "Interface\\Icons\\Spell_Holy_AuraOfLight",
    },
    HUNTER = {
        ["Beast Mastery"] = "Interface\\Icons\\Ability_Hunter_BeastTaming",
        ["Marksmanship"] = "Interface\\Icons\\Ability_Marksmanship",
        ["Survival"] = "Interface\\Icons\\Ability_Hunter_SwiftStrike",
    },
    ROGUE = {
        ["Assassination"] = "Interface\\Icons\\Ability_Rogue_Eviscerate",
        ["Combat"] = "Interface\\Icons\\Ability_BackStab",
        ["Subtlety"] = "Interface\\Icons\\Ability_Stealth",
    },
    PRIEST = {
        ["Discipline"] = "Interface\\Icons\\Spell_Holy_WordFortitude",
        ["Holy"] = "Interface\\Icons\\Spell_Holy_HolyBolt",
        ["Shadow"] = "Interface\\Icons\\Spell_Shadow_ShadowWordPain",
    },
    SHAMAN = {
        ["Elemental"] = "Interface\\Icons\\Spell_Nature_Lightning",
        ["Enhancement"] = "Interface\\Icons\\Spell_Nature_LightningShield",
        ["Restoration"] = "Interface\\Icons\\Spell_Nature_MagicImmunity",
    },
    MAGE = {
        ["Arcane"] = "Interface\\Icons\\Spell_Holy_MagicalSentry",
        ["Fire"] = "Interface\\Icons\\Spell_Fire_FireBolt02",
        ["Frost"] = "Interface\\Icons\\Spell_Frost_FrostBolt02",
    },
    WARLOCK = {
        ["Affliction"] = "Interface\\Icons\\Spell_Shadow_DeathCoil",
        ["Demonology"] = "Interface\\Icons\\Spell_Shadow_Metamorphosis",
        ["Destruction"] = "Interface\\Icons\\Spell_Shadow_RainOfFire",
    },
    DRUID = {
        ["Balance"] = "Interface\\Icons\\Spell_Nature_StarFall",
        ["Feral"] = "Interface\\Icons\\Ability_Racial_BearForm",
        ["Feral Combat"] = "Interface\\Icons\\Ability_Racial_BearForm",
        ["Restoration"] = "Interface\\Icons\\Spell_Nature_HealingTouch",
    },
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
