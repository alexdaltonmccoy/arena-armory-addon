-- AceDB profile defaults.
local _, AA = ...

AA.defaults = {
    profile = {
        locked = false,
        position = { point = "CENTER", relativePoint = "CENTER", x = 300, y = 100 },

        frames = {
            style = "modern", -- "modern" (flat, Midnight-like) or "classic"
            width = 220,
            height = 44,
            -- Must clear the cast bar (~20px) + cooldown row (~22px) that
            -- hang below each frame, or rows overlap their neighbors.
            spacing = 56,
            scale = 1.0,
            growDown = true,
            classColoredHealth = true,
            showNames = true,
            showPowerBar = true,
            -- Tall enough for the spec label + power value text.
            powerBarHeight = 14,
            fontSize = 11,
            healthTextMode = "both",  -- "none" | "value" | "percent" | "both"
            powerTextMode = "both",   -- "none" | "value" | "percent" | "both"
            specPosition = "power",   -- "power" (below name) or "health" (right side)
        },

        castbar = {
            enabled = true,
            height = 18,
        },

        auras = {
            enabled = true,
        },

        trinket = {
            enabled = true,
            size = 44,
            -- Racial CC breaks (Will of the Forsaken) get their own icon:
            -- they don't share the trinket cooldown in TBC.
            trackRacial = true,
        },

        dr = {
            enabled = true,
            iconSize = 22,
            position = "left", -- "left" or "right" of the frame
        },

        cooldowns = {
            enabled = true,
            iconSize = 20,
            maxIcons = 8,
            position = "below", -- "below" or "right" of the frame
        },

        specDetection = {
            enabled = true,
        },

        announcer = {
            enabled = true,
            useSounds = true,  -- Media/Voice/*.ogg via PlaySoundFile (reliable)
            useTTS = false,    -- optional; Anniversary TTS is flaky
            alertSound = true, -- beep only if voice clip fails and TTS is off
            raidWarning = true,
            -- "off" | "self" | "party" — party = majors only (trinket/drink/walls/lust/res)
            chatCallout = "party",
            channel = "Master",
            voice = "auto",
            trinket = true,
            drink = true,
            casts = true,      -- CC callouts
            cooldowns = true,  -- Bubble / Cloak / Ice Block / etc.
            interrupts = false, -- Kick/Pummel (noisy; opt-in)
            resurrect = true,
            lowHealth = true,
            lowHealthThreshold = 0.3,
        },

        partyMark = {
            enabled = true,
            announce = true, -- party chat when marks are applied
            -- Raid target index 1–8 by class (class-color defaults).
            classIcons = {
                ROGUE = 1,   -- Star (yellow)
                DRUID = 2,   -- Circle (orange)
                WARLOCK = 3, -- Diamond (purple)
                HUNTER = 4,  -- Triangle (green)
                PRIEST = 5,  -- Moon (white)
                MAGE = 6,    -- Square (blue)
                SHAMAN = 6,  -- Square (blue)
                PALADIN = 7, -- Cross
                WARRIOR = 8, -- Skull
            },
        },

        recorder = {
            enabled = true,
        },

        analytics = {
            enabled = true,
            announceComp = true, -- "You are 2-1 vs Rogue/Priest" on arena entry
            postMatch = true,    -- updated record in chat after each game
        },
    },
}
