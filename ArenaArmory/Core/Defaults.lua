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
            useTTS = true,
            voice = "auto",
            trinket = true,
            drink = true,
            casts = true,
            resurrect = true,
            lowHealth = true,
            lowHealthThreshold = 0.3,
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
