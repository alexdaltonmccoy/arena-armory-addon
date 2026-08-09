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
-- Interrupt casts matched by NAME (any rank): the recorder logs every attempt
-- so the site can compute juke/efficiency rates from attempts vs. lands.
-- Earth Shock is excluded - it's a rotational nuke, not a dedicated interrupt.
-------------------------------------------------------------------------------

AA.INTERRUPT_CAST_NAMES = {
    ["Kick"] = true,
    ["Pummel"] = true,
    ["Counterspell"] = true,
    ["Spell Lock"] = true,
    ["Shield Bash"] = true,
    ["Silencing Shot"] = true,
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
-- Announcer: spellID -> { sound = file key under Media/Voice/, cat = group }
-- cat: "cc" | "cooldown" | "interrupt"  (toggled in options)
-- Raid-warning text comes from AA.VOICE_TEXT[sound].
-------------------------------------------------------------------------------

AA.VOICE_TEXT = {
    trinket = "Trinket",
    blind = "Blind",
    polymorph = "Polymorph",
    fear = "Fear",
    howl = "Howl of Terror",
    cyclone = "Cyclone",
    repentance = "Repentance",
    wyvern = "Wyvern",
    hibernate = "Hibernate",
    roots = "Roots",
    manaburn = "Mana Burn",
    seduction = "Seduction",
    psychicscream = "Psychic Scream",
    hammer = "Hammer of Justice",
    scatter = "Scatter",
    freezingtrap = "Freezing Trap",
    sap = "Sap",
    gouge = "Gouge",
    kidney = "Kidney Shot",
    cheapshot = "Cheap Shot",
    deathcoil = "Death Coil",
    shadowfury = "Shadowfury",
    intimidation = "Intimidating Shout",
    silence = "Silence",
    counterspell = "Counterspell",
    kick = "Kick",
    pummel = "Pummel",
    spelllock = "Spell Lock",
    bubble = "Bubble",
    iceblock = "Ice Block",
    cloak = "Cloak",
    evasion = "Evasion",
    vanish = "Vanish",
    deterrence = "Deterrence",
    bop = "Blessing of Protection",
    painsuppression = "Pain Suppression",
    natureswiftness = "Nature's Swiftness",
    grounding = "Grounding",
    spellreflection = "Spell Reflection",
    coldblood = "Cold Blood",
    adrenalinerush = "Adrenaline Rush",
    bloodlust = "Bloodlust",
    heroism = "Heroism",
    innervate = "Innervate",
    barkskin = "Barkskin",
    presenceofmind = "Presence of Mind",
    avengingwrath = "Avenging Wrath",
    drinking = "Drinking",
    resurrect = "Resurrect",
    lowhealth = "Low health",
    freedom = "Freedom",
    divineprotection = "Divine Protection",
    layonhands = "Lay on Hands",
    intercept = "Intercept",
    charge = "Charge",
    deathwish = "Death Wish",
    recklessness = "Recklessness",
    berserkerrage = "Berserker Rage",
    readiness = "Readiness",
    beastwithin = "Beast Within",
    petintimidation = "Intimidation",
    silencingshot = "Silencing Shot",
    sprint = "Sprint",
    preparation = "Preparation",
    shadowstep = "Shadowstep",
    premeditation = "Premeditation",
    stealth = "Stealth",
    powerinfusion = "Power Infusion",
    fearward = "Fear Ward",
    shadowfiend = "Shadowfiend",
    elementalmastery = "Elemental Mastery",
    shamanisticrage = "Shamanistic Rage",
    tremor = "Tremor Totem",
    manatide = "Mana Tide",
    icyveins = "Icy Veins",
    arcanepower = "Arcane Power",
    combustion = "Combustion",
    coldsnap = "Cold Snap",
    blink = "Blink",
    frostnova = "Frost Nova",
    dragonsbreath = "Dragon's Breath",
    spellsteal = "Spellsteal",
    feldomination = "Fel Domination",
    soulstone = "Soulstone",
    bash = "Bash",
    feralcharge = "Feral Charge",
    wotf = "Will of the Forsaken",
    warstomp = "War Stomp",
    stoneform = "Stoneform",
    escapeartist = "Escape Artist",
}

local function A(sound, cat)
    return { sound = sound, cat = cat or "cc" }
end

AA.ANNOUNCE_SPELLS = {
    -- CC / control
    [118] = A("polymorph"), [12824] = A("polymorph"), [12825] = A("polymorph"),
    [12826] = A("polymorph"), [28271] = A("polymorph"), [28272] = A("polymorph"),
    [5782] = A("fear"), [6213] = A("fear"), [6215] = A("fear"),
    [5484] = A("howl"), [17928] = A("howl"),
    [33786] = A("cyclone"),
    [20066] = A("repentance"),
    [19386] = A("wyvern"), [24132] = A("wyvern"), [24133] = A("wyvern"), [27068] = A("wyvern"),
    [2637] = A("hibernate"), [18657] = A("hibernate"), [18658] = A("hibernate"),
    [339] = A("roots"), [1062] = A("roots"), [5195] = A("roots"), [5196] = A("roots"),
    [9852] = A("roots"), [9853] = A("roots"), [26989] = A("roots"),
    [8129] = A("manaburn"), [27224] = A("manaburn"), -- Drain Mana uses same callout
    [6358] = A("seduction"),
    [8122] = A("psychicscream"), [8124] = A("psychicscream"),
    [10888] = A("psychicscream"), [10890] = A("psychicscream"),
    [2094] = A("blind"),
    [853] = A("hammer"), [5588] = A("hammer"), [5589] = A("hammer"), [10308] = A("hammer"),
    [19503] = A("scatter"),
    [1499] = A("freezingtrap"), [14310] = A("freezingtrap"), [14311] = A("freezingtrap"),
    [6770] = A("sap"), [2070] = A("sap"), [11297] = A("sap"),
    [1776] = A("gouge"), [1777] = A("gouge"), [8629] = A("gouge"),
    [11285] = A("gouge"), [11286] = A("gouge"), [38764] = A("gouge"),
    [408] = A("kidney"), [8643] = A("kidney"),
    [1833] = A("cheapshot"),
    [6789] = A("deathcoil"), [17925] = A("deathcoil"), [17926] = A("deathcoil"), [27223] = A("deathcoil"),
    [30283] = A("shadowfury"), [30413] = A("shadowfury"), [30414] = A("shadowfury"),
    [5246] = A("intimidation"),
    [15487] = A("silence"),

    -- Interrupts
    [2139] = A("counterspell", "interrupt"),
    [1766] = A("kick", "interrupt"), [1767] = A("kick", "interrupt"),
    [1768] = A("kick", "interrupt"), [1769] = A("kick", "interrupt"), [38768] = A("kick", "interrupt"),
    [6552] = A("pummel", "interrupt"), [6554] = A("pummel", "interrupt"),
    [19244] = A("spelllock", "interrupt"), [19647] = A("spelllock", "interrupt"),

    -- More CC / control
    [5211] = A("bash"), [6798] = A("bash"), [8983] = A("bash"),
    [122] = A("frostnova"), [865] = A("frostnova"), [6131] = A("frostnova"), [10230] = A("frostnova"),
    [27088] = A("frostnova"),
    [31661] = A("dragonsbreath"), [33041] = A("dragonsbreath"), [33042] = A("dragonsbreath"),
    [33043] = A("dragonsbreath"),
    [20549] = A("warstomp"),

    -- Interrupts (extra)
    [34490] = A("silencingshot", "interrupt"),

    -- Major cooldowns
    [642] = A("bubble", "cooldown"), [1020] = A("bubble", "cooldown"), -- Divine Shield ranks
    [498] = A("divineprotection", "cooldown"), -- Divine Protection
    [45438] = A("iceblock", "cooldown"),
    [31224] = A("cloak", "cooldown"),
    [5277] = A("evasion", "cooldown"), [26669] = A("evasion", "cooldown"),
    [1856] = A("vanish", "cooldown"), [1857] = A("vanish", "cooldown"), [26889] = A("vanish", "cooldown"),
    [19263] = A("deterrence", "cooldown"),
    [1022] = A("bop", "cooldown"), [5599] = A("bop", "cooldown"), [10278] = A("bop", "cooldown"),
    [1044] = A("freedom", "cooldown"), -- Blessing of Freedom
    [633] = A("layonhands", "cooldown"), [2800] = A("layonhands", "cooldown"),
    [10310] = A("layonhands", "cooldown"), [27154] = A("layonhands", "cooldown"),
    [33206] = A("painsuppression", "cooldown"),
    [10060] = A("powerinfusion", "cooldown"),
    [6346] = A("fearward", "cooldown"),
    [34433] = A("shadowfiend", "cooldown"),
    [16188] = A("natureswiftness", "cooldown"), [17116] = A("natureswiftness", "cooldown"),
    [8177] = A("grounding", "cooldown"),
    [8143] = A("tremor", "cooldown"), -- Tremor Totem
    [16190] = A("manatide", "cooldown"), -- Mana Tide Totem
    [16166] = A("elementalmastery", "cooldown"),
    [30823] = A("shamanisticrage", "cooldown"),
    -- Spell Reflection / Berserker Rage: previously omitted as too noisy;
    -- re-enabled per Alex. IDs match AA.COOLDOWN_SPELLS above (single rank
    -- each in TBC, already live there for the icon tracker).
    [23920] = A("spellreflection", "cooldown"), -- Warrior Spell Reflection
    [18499] = A("berserkerrage", "cooldown"), -- Warrior Berserker Rage
    [14177] = A("coldblood", "cooldown"),
    [13750] = A("adrenalinerush", "cooldown"),
    [14185] = A("preparation", "cooldown"),
    [36554] = A("shadowstep", "cooldown"),
    [2825] = A("bloodlust", "cooldown"),
    [32182] = A("heroism", "cooldown"),
    [29166] = A("innervate", "cooldown"),
    [22812] = A("barkskin", "cooldown"),
    [12043] = A("presenceofmind", "cooldown"),
    [12472] = A("icyveins", "cooldown"),
    [12042] = A("arcanepower", "cooldown"),
    [11129] = A("combustion", "cooldown"),
    [11958] = A("coldsnap", "cooldown"),
    [31884] = A("avengingwrath", "cooldown"),
    [12292] = A("deathwish", "cooldown"),
    [1719] = A("recklessness", "cooldown"),
    [23989] = A("readiness", "cooldown"),
    [34692] = A("beastwithin", "cooldown"),
    [19577] = A("petintimidation", "cooldown"), -- Hunter Intimidation
    [18708] = A("feldomination", "cooldown"),
    [20707] = A("soulstone", "cooldown"), -- Soulstone Resurrection
    -- Racials (CC break)
    [7744] = A("wotf", "cooldown"), -- Will of the Forsaken

    -- Mobility / utility (Tier 1: voice clips already recorded, previously
    -- unwired - see Media/Voice/*.ogg). Spell IDs verified against
    -- tbc.wowhead.com and cross-checked against AA.COOLDOWN_SPELLS above,
    -- which already independently tracks Intercept/Sprint/Blink/Feral
    -- Charge for the icon tracker under the same IDs.
    [100] = A("charge", "cooldown"), -- Warrior Charge (single rank in TBC)
    [20252] = A("intercept", "cooldown"), -- Warrior Intercept (single rank in TBC)
    [1953] = A("blink", "cooldown"), -- Mage Blink
    [30449] = A("spellsteal", "cooldown"), -- Mage Spellsteal
    [16979] = A("feralcharge", "cooldown"), -- Druid Feral Charge (Bear - the only version in TBC)
    [2983] = A("sprint", "cooldown"), [8696] = A("sprint", "cooldown"), [11305] = A("sprint", "cooldown"), -- Rogue Sprint (all 3 ranks)
    [14183] = A("premeditation", "cooldown"), -- Rogue Premeditation
    [1784] = A("stealth", "cooldown"), [1785] = A("stealth", "cooldown"),
    [1786] = A("stealth", "cooldown"), [1787] = A("stealth", "cooldown"), -- Rogue Stealth (all 4 ranks)
    [20594] = A("stoneform", "cooldown"), -- Dwarf racial: Stoneform
    [20589] = A("escapeartist", "cooldown"), -- Gnome racial: Escape Artist
}

-- Party-chat whitelist when chatCallout=party. Keep this tiny — voice/raid
-- warning still cover the rest. No CC, no Shadowstep/Kidney/PI spam.
AA.PARTY_CHAT_SOUNDS = {
    trinket = true,
    drinking = true,
    -- Immunities / walls
    bubble = true,
    iceblock = true,
    cloak = true,
    evasion = true,
    divineprotection = true,
    deterrence = true,
    barkskin = true,
    painsuppression = true,
    vanish = true,
    bop = true,
    layonhands = true,
    -- Raid-swinging utility
    bloodlust = true,
    heroism = true,
    innervate = true,
    grounding = true,
    natureswiftness = true,
    manatide = true,
    -- Res
    resurrect = true,
    soulstone = true,
}

-- Legacy alias used by older debug/docs; maps to sound keys' display text.
AA.ANNOUNCE_CASTS = setmetatable({}, {
    __index = function(_, spellId)
        local e = AA.ANNOUNCE_SPELLS[spellId]
        return e and AA.VOICE_TEXT[e.sound] or nil
    end,
})

-- Resurrection casts (announce loudly).
AA.ANNOUNCE_RES = {
    [2006] = "resurrect", [2010] = "resurrect", [10880] = "resurrect",
    [10881] = "resurrect", [20770] = "resurrect", -- Priest
    [7328] = "resurrect", [10322] = "resurrect", [10324] = "resurrect",
    [20772] = "resurrect", [20773] = "resurrect", -- Paladin Redemption
    [2008] = "resurrect", [20609] = "resurrect", [20610] = "resurrect",
    [20776] = "resurrect", [20777] = "resurrect", -- Shaman Ancestral Spirit
    [20484] = "resurrect", [20739] = "resurrect", [20742] = "resurrect",
    [20747] = "resurrect", [20748] = "resurrect", [26994] = "resurrect", -- Rebirth
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
