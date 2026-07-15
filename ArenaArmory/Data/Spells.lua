-- TBC (2.5.6) spell data: trinkets, tracked cooldowns, spec detection, announcer triggers.
local _, AA = ...

-------------------------------------------------------------------------------
-- Trinket / CC-break
-------------------------------------------------------------------------------

-- spellID -> cooldown seconds
AA.TRINKET_SPELLS = {
    [42292] = 120, -- PvP Trinket (Medallion of the Alliance/Horde)
    [59752] = 120, -- Every Man for Himself (safety net; not expected in TBC)
}

AA.RACIAL_CC_BREAKS = {
    [7744] = 120, -- Will of the Forsaken
}

-------------------------------------------------------------------------------
-- Tracked enemy cooldowns: spellID -> { cd = seconds, class = classToken }
-- Shown as icon rows under each arena frame after first observed use.
-------------------------------------------------------------------------------

AA.COOLDOWN_SPELLS = {
    -- Warrior
    [6552]  = { cd = 10,  class = "WARRIOR" }, -- Pummel
    [20252] = { cd = 30,  class = "WARRIOR" }, -- Intercept
    [23920] = { cd = 10,  class = "WARRIOR" }, -- Spell Reflection
    [5246]  = { cd = 180, class = "WARRIOR" }, -- Intimidating Shout
    [12292] = { cd = 180, class = "WARRIOR" }, -- Death Wish
    [1719]  = { cd = 1800, class = "WARRIOR" }, -- Recklessness
    [18499] = { cd = 30,  class = "WARRIOR" }, -- Berserker Rage

    -- Paladin
    [642]   = { cd = 300, class = "PALADIN" }, -- Divine Shield
    [10278] = { cd = 180, class = "PALADIN" }, -- Blessing of Protection
    [1044]  = { cd = 25,  class = "PALADIN" }, -- Blessing of Freedom
    [10308] = { cd = 60,  class = "PALADIN" }, -- Hammer of Justice
    [20066] = { cd = 60,  class = "PALADIN" }, -- Repentance
    [31884] = { cd = 180, class = "PALADIN" }, -- Avenging Wrath

    -- Hunter
    [34490] = { cd = 20,  class = "HUNTER" }, -- Silencing Shot
    [19503] = { cd = 30,  class = "HUNTER" }, -- Scatter Shot
    [19263] = { cd = 300, class = "HUNTER" }, -- Deterrence
    [14311] = { cd = 30,  class = "HUNTER" }, -- Freezing Trap
    [19577] = { cd = 60,  class = "HUNTER" }, -- Intimidation
    [23989] = { cd = 300, class = "HUNTER" }, -- Readiness
    [34692] = { cd = 120, class = "HUNTER" }, -- The Beast Within

    -- Rogue
    [38768] = { cd = 10,  class = "ROGUE" }, -- Kick
    [2094]  = { cd = 180, class = "ROGUE" }, -- Blind
    [26889] = { cd = 300, class = "ROGUE" }, -- Vanish
    [31224] = { cd = 60,  class = "ROGUE" }, -- Cloak of Shadows
    [26669] = { cd = 300, class = "ROGUE" }, -- Evasion
    [11305] = { cd = 300, class = "ROGUE" }, -- Sprint
    [14185] = { cd = 600, class = "ROGUE" }, -- Preparation
    [13750] = { cd = 300, class = "ROGUE" }, -- Adrenaline Rush
    [14177] = { cd = 180, class = "ROGUE" }, -- Cold Blood

    -- Priest
    [10890] = { cd = 30,  class = "PRIEST" }, -- Psychic Scream
    [15487] = { cd = 45,  class = "PRIEST" }, -- Silence
    [10060] = { cd = 180, class = "PRIEST" }, -- Power Infusion
    [33206] = { cd = 120, class = "PRIEST" }, -- Pain Suppression
    [6346]  = { cd = 180, class = "PRIEST" }, -- Fear Ward
    [34433] = { cd = 300, class = "PRIEST" }, -- Shadowfiend

    -- Shaman
    [8177]  = { cd = 15,  class = "SHAMAN" }, -- Grounding Totem
    [16188] = { cd = 180, class = "SHAMAN" }, -- Nature's Swiftness
    [16166] = { cd = 180, class = "SHAMAN" }, -- Elemental Mastery
    [30823] = { cd = 120, class = "SHAMAN" }, -- Shamanistic Rage
    [2825]  = { cd = 600, class = "SHAMAN" }, -- Bloodlust
    [32182] = { cd = 600, class = "SHAMAN" }, -- Heroism

    -- Mage
    [2139]  = { cd = 24,  class = "MAGE" }, -- Counterspell
    [45438] = { cd = 300, class = "MAGE" }, -- Ice Block
    [1953]  = { cd = 15,  class = "MAGE" }, -- Blink
    [11958] = { cd = 480, class = "MAGE" }, -- Cold Snap
    [12472] = { cd = 180, class = "MAGE" }, -- Icy Veins
    [12043] = { cd = 180, class = "MAGE" }, -- Presence of Mind
    [12042] = { cd = 180, class = "MAGE" }, -- Arcane Power
    [11129] = { cd = 180, class = "MAGE" }, -- Combustion

    -- Warlock
    [19647] = { cd = 24,  class = "WARLOCK" }, -- Spell Lock (Felhunter)
    [27223] = { cd = 120, class = "WARLOCK" }, -- Death Coil
    [17928] = { cd = 40,  class = "WARLOCK" }, -- Howl of Terror
    [30414] = { cd = 20,  class = "WARLOCK" }, -- Shadowfury
    [18708] = { cd = 900, class = "WARLOCK" }, -- Fel Domination

    -- Druid
    [8983]  = { cd = 60,  class = "DRUID" }, -- Bash
    [16979] = { cd = 15,  class = "DRUID" }, -- Feral Charge
    [17116] = { cd = 180, class = "DRUID" }, -- Nature's Swiftness
    [22812] = { cd = 60,  class = "DRUID" }, -- Barkskin
    [29166] = { cd = 360, class = "DRUID" }, -- Innervate
}

-------------------------------------------------------------------------------
-- Spec detection: spellID -> { class = classToken, spec = "SpecName" }
-- First matching observed spell locks the spec for that opponent.
-------------------------------------------------------------------------------

AA.SPEC_SPELLS = {
    -- Warrior
    [30330] = { class = "WARRIOR", spec = "Arms" },        -- Mortal Strike
    [30335] = { class = "WARRIOR", spec = "Fury" },        -- Bloodthirst
    [30356] = { class = "WARRIOR", spec = "Protection" },  -- Shield Slam
    [12292] = { class = "WARRIOR", spec = "Fury" },        -- Death Wish

    -- Paladin
    [33072] = { class = "PALADIN", spec = "Holy" },        -- Holy Shock
    [20216] = { class = "PALADIN", spec = "Holy" },        -- Divine Favor
    [31842] = { class = "PALADIN", spec = "Holy" },        -- Divine Illumination
    [27179] = { class = "PALADIN", spec = "Protection" },  -- Holy Shield
    [35395] = { class = "PALADIN", spec = "Retribution" }, -- Crusader Strike
    [20066] = { class = "PALADIN", spec = "Retribution" }, -- Repentance

    -- Hunter
    [19574] = { class = "HUNTER", spec = "Beast Mastery" }, -- Bestial Wrath
    [34692] = { class = "HUNTER", spec = "Beast Mastery" }, -- The Beast Within
    [19577] = { class = "HUNTER", spec = "Beast Mastery" }, -- Intimidation
    [34490] = { class = "HUNTER", spec = "Marksmanship" },  -- Silencing Shot
    [27068] = { class = "HUNTER", spec = "Survival" },      -- Wyvern Sting
    [23989] = { class = "HUNTER", spec = "Survival" },      -- Readiness

    -- Rogue
    [34413] = { class = "ROGUE", spec = "Assassination" }, -- Mutilate
    [14177] = { class = "ROGUE", spec = "Assassination" }, -- Cold Blood
    [13750] = { class = "ROGUE", spec = "Combat" },        -- Adrenaline Rush
    [13877] = { class = "ROGUE", spec = "Combat" },        -- Blade Flurry
    [36554] = { class = "ROGUE", spec = "Subtlety" },      -- Shadowstep
    [14185] = { class = "ROGUE", spec = "Subtlety" },      -- Preparation
    [26864] = { class = "ROGUE", spec = "Subtlety" },      -- Hemorrhage

    -- Priest
    [33206] = { class = "PRIEST", spec = "Discipline" },   -- Pain Suppression
    [10060] = { class = "PRIEST", spec = "Discipline" },   -- Power Infusion
    [34866] = { class = "PRIEST", spec = "Holy" },         -- Circle of Healing
    [15473] = { class = "PRIEST", spec = "Shadow" },       -- Shadowform
    [34917] = { class = "PRIEST", spec = "Shadow" },       -- Vampiric Touch

    -- Shaman
    [30706] = { class = "SHAMAN", spec = "Elemental" },    -- Totem of Wrath
    [16166] = { class = "SHAMAN", spec = "Elemental" },    -- Elemental Mastery
    [17364] = { class = "SHAMAN", spec = "Enhancement" },  -- Stormstrike
    [30823] = { class = "SHAMAN", spec = "Enhancement" },  -- Shamanistic Rage
    [16190] = { class = "SHAMAN", spec = "Restoration" },  -- Mana Tide Totem
    [32594] = { class = "SHAMAN", spec = "Restoration" },  -- Earth Shield

    -- Mage
    [12042] = { class = "MAGE", spec = "Arcane" },         -- Arcane Power
    [12043] = { class = "MAGE", spec = "Arcane" },         -- Presence of Mind
    [11129] = { class = "MAGE", spec = "Fire" },           -- Combustion
    [33043] = { class = "MAGE", spec = "Fire" },           -- Dragon's Breath
    [33405] = { class = "MAGE", spec = "Frost" },          -- Ice Barrier
    [31687] = { class = "MAGE", spec = "Frost" },          -- Summon Water Elemental
    [12472] = { class = "MAGE", spec = "Frost" },          -- Icy Veins

    -- Warlock
    [30405] = { class = "WARLOCK", spec = "Affliction" },   -- Unstable Affliction
    [18223] = { class = "WARLOCK", spec = "Affliction" },   -- Curse of Exhaustion
    [19028] = { class = "WARLOCK", spec = "Demonology" },   -- Soul Link
    [30146] = { class = "WARLOCK", spec = "Demonology" },   -- Summon Felguard
    [30546] = { class = "WARLOCK", spec = "Destruction" },  -- Shadowburn
    [30912] = { class = "WARLOCK", spec = "Destruction" },  -- Conflagrate
    [30414] = { class = "WARLOCK", spec = "Destruction" },  -- Shadowfury

    -- Druid
    [24858] = { class = "DRUID", spec = "Balance" },       -- Moonkin Form
    [33831] = { class = "DRUID", spec = "Balance" },       -- Force of Nature
    [33983] = { class = "DRUID", spec = "Feral" },         -- Mangle (Cat)
    [33987] = { class = "DRUID", spec = "Feral" },         -- Mangle (Bear)
    [18562] = { class = "DRUID", spec = "Restoration" },   -- Swiftmend
    [33891] = { class = "DRUID", spec = "Restoration" },   -- Tree of Life
    [17116] = { class = "DRUID", spec = "Restoration" },   -- Nature's Swiftness
}

-------------------------------------------------------------------------------
-- Spec detection from visible BUFFS (all ranks): works at the gates, before
-- a single spell is cast - forms, talent auras, and shields give specs away.
-- spellID -> { class = classToken, spec = "SpecName" }
-------------------------------------------------------------------------------

AA.SPEC_BUFFS = {
    -- Priest
    [15473] = { class = "PRIEST", spec = "Shadow" },       -- Shadowform

    -- Druid
    [24858] = { class = "DRUID", spec = "Balance" },       -- Moonkin Form
    [24907] = { class = "DRUID", spec = "Balance" },       -- Moonkin Aura
    [33891] = { class = "DRUID", spec = "Restoration" },   -- Tree of Life
    [34123] = { class = "DRUID", spec = "Restoration" },   -- Tree of Life aura
    [17007] = { class = "DRUID", spec = "Feral" },         -- Leader of the Pack

    -- Hunter (Trueshot Aura ranks)
    [19506] = { class = "HUNTER", spec = "Marksmanship" },
    [20905] = { class = "HUNTER", spec = "Marksmanship" },
    [20906] = { class = "HUNTER", spec = "Marksmanship" },
    [27066] = { class = "HUNTER", spec = "Marksmanship" },

    -- Mage (Ice Barrier ranks)
    [11426] = { class = "MAGE", spec = "Frost" },
    [13031] = { class = "MAGE", spec = "Frost" },
    [13032] = { class = "MAGE", spec = "Frost" },
    [13033] = { class = "MAGE", spec = "Frost" },
    [27134] = { class = "MAGE", spec = "Frost" },
    [33405] = { class = "MAGE", spec = "Frost" },

    -- Shaman (Earth Shield ranks)
    [974]   = { class = "SHAMAN", spec = "Restoration" },
    [32593] = { class = "SHAMAN", spec = "Restoration" },
    [32594] = { class = "SHAMAN", spec = "Restoration" },

    -- Warlock
    [19028] = { class = "WARLOCK", spec = "Demonology" },  -- Soul Link (talent)
    [25228] = { class = "WARLOCK", spec = "Demonology" },  -- Soul Link (buff)

    -- Paladin
    [20218] = { class = "PALADIN", spec = "Retribution" }, -- Sanctity Aura

    -- Warrior (Rampage ranks, shows up once combat starts)
    [29801] = { class = "WARRIOR", spec = "Fury" },
    [30030] = { class = "WARRIOR", spec = "Fury" },
    [30033] = { class = "WARRIOR", spec = "Fury" },

    -- Shaman Elemental (Totem of Wrath buff)
    [30708] = { class = "SHAMAN", spec = "Elemental" },
}

-------------------------------------------------------------------------------
-- Announcer: enemy cast starts worth calling out (spellID -> label)
-------------------------------------------------------------------------------

AA.ANNOUNCE_CASTS = {
    [12826] = "Polymorph",       -- Polymorph (top rank)
    [28271] = "Polymorph",       -- Polymorph: Turtle
    [28272] = "Polymorph",       -- Polymorph: Pig
    [6215]  = "Fear",            -- Fear
    [17928] = "Howl of Terror",
    [33786] = "Cyclone",
    [20066] = "Repentance",
    [27068] = "Wyvern Sting",
    [18658] = "Hibernate",
    [26989] = "Entangling Roots",
    [8129]  = "Mana Burn",
    [27224] = "Drain Mana",
    [6358]  = "Seduction",
    [10890] = "Psychic Scream",  -- instant, caught via SPELL_CAST_SUCCESS
    [2094]  = "Blind",
}

-- Resurrection casts (announce loudly).
AA.ANNOUNCE_RES = {
    [20770] = "Resurrection",   -- Priest
    [20773] = "Redemption",     -- Paladin
    [20777] = "Ancestral Spirit", -- Shaman
    [26994] = "Rebirth",        -- Druid
}

-- Drink aura spell IDs (any rank) plus name fallback.
AA.DRINK_AURAS = {
    [430] = true, [431] = true, [432] = true, [1133] = true, [1135] = true,
    [1137] = true, [10250] = true, [22734] = true, [27089] = true,
    [34291] = true, [43182] = true, [43706] = true, [46755] = true,
}
AA.DRINK_NAME = "Drink"

-------------------------------------------------------------------------------
-- Important auras to overlay on frames (CC / immunities), spellID -> priority
-- Higher priority wins when multiple are active.
-------------------------------------------------------------------------------

AA.IMPORTANT_AURAS = {
    -- Immunities / big defensives
    [642]   = 10, -- Divine Shield
    [45438] = 10, -- Ice Block
    [19263] = 9,  -- Deterrence
    [31224] = 9,  -- Cloak of Shadows
    [10278] = 9,  -- Blessing of Protection
    [33206] = 8,  -- Pain Suppression

    -- CC
    [12826] = 7, [28271] = 7, [28272] = 7, -- Polymorph
    [2094]  = 7, -- Blind
    [6215]  = 7, -- Fear
    [5246]  = 7, -- Intimidating Shout
    [10890] = 7, -- Psychic Scream
    [33786] = 7, -- Cyclone
    [20066] = 7, -- Repentance
    [8643]  = 6, -- Kidney Shot
    [1833]  = 6, -- Cheap Shot
    [10308] = 6, -- Hammer of Justice
    [19503] = 6, -- Scatter Shot
    [14311] = 7, -- Freezing Trap
    [18658] = 6, -- Hibernate
    [26989] = 5, -- Entangling Roots
    [27068] = 7, -- Wyvern Sting
    [6358]  = 7, -- Seduction
    [11297] = 7, -- Sap
    [38764] = 6, -- Gouge
    [15487] = 6, -- Silence
    [18469] = 5, -- Counterspell - Silenced
    [34490] = 5, -- Silencing Shot
}
