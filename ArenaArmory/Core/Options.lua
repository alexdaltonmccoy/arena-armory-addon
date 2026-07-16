-- AceConfig options and /aa slash commands.
local _, AA = ...
local addon = AA.addon

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local function Get(info)
    local db = AA.db.profile
    for i = 1, #info - 1 do
        db = db[info[i]]
    end
    return db[info[#info]]
end

local function Set(info, value)
    local db = AA.db.profile
    for i = 1, #info - 1 do
        db = db[info[i]]
    end
    db[info[#info]] = value
    -- Apply everything live so toggles/sliders take effect immediately,
    -- including in /aa test mode.
    if AA.Frames then
        AA.Frames:ApplySizes()
        AA.Frames:ApplyStyles()
        AA.Frames:UpdateLockState()
    end
    if AA.Trinket then AA.Trinket:ApplyOptions() end
    if AA.DR then AA.DR:ApplyOptions() end
    if AA.Cooldowns then AA.Cooldowns:ApplyOptions() end
    if AA.Auras then AA.Auras:ApplyOptions() end
    -- Re-seed sample data so re-enabled trackers reappear immediately.
    if AA.testMode and AA.TestMode then AA.TestMode:Refresh() end
end

local options = {
    type = "group",
    name = "Arena Armory",
    get = Get,
    set = Set,
    args = {
        locked = {
            type = "toggle", order = 1,
            name = "Lock frames",
            desc = "Lock the anchor so it can't be dragged.",
        },
        frames = {
            type = "group", order = 10, name = "Frames", inline = false,
            args = {
                style = {
                    type = "select", order = 0, name = "Bar style",
                    desc = "Modern is a flat, Midnight-style look; Classic uses the traditional glossy WoW bar texture.",
                    values = { modern = "Modern (flat)", classic = "Classic" },
                },
                width = { type = "range", order = 1, name = "Bar width", min = 100, max = 400, step = 5 },
                height = { type = "range", order = 2, name = "Frame height", min = 24, max = 80, step = 2 },
                spacing = { type = "range", order = 3, name = "Spacing", min = 0, max = 100, step = 2 },
                scale = { type = "range", order = 4, name = "Scale", min = 0.5, max = 2, step = 0.05 },
                growDown = { type = "toggle", order = 5, name = "Grow downwards" },
                classColoredHealth = { type = "toggle", order = 6, name = "Class-colored health" },
                showNames = { type = "toggle", order = 7, name = "Show names" },
                showPowerBar = { type = "toggle", order = 8, name = "Show power bar" },
                powerBarHeight = {
                    type = "range", order = 9, name = "Power bar height",
                    min = 4, max = 24, step = 1,
                    desc = "14+ recommended when the spec label or power text is shown on the bar.",
                },
                fontSize = {
                    type = "range", order = 10, name = "Text size",
                    min = 8, max = 16, step = 1,
                    desc = "Base size for the name, spec, health, and power texts.",
                },
                healthTextMode = {
                    type = "select", order = 11, name = "Health text",
                    desc = "What to show on the right of the health bar.",
                    values = { none = "Nothing", value = "Value", percent = "Percent", both = "Value (percent)" },
                },
                powerTextMode = {
                    type = "select", order = 12, name = "Power text",
                    desc = "What to show on the right of the power bar.",
                    values = { none = "Nothing", value = "Value", percent = "Percent", both = "Value (percent)" },
                },
                specPosition = {
                    type = "select", order = 13, name = "Spec label position",
                    desc = "Detected enemy spec: on the power bar directly below the name, or on the right side of the health bar.",
                    values = { power = "Power bar (below name)", health = "Health bar (right side)" },
                },
            },
        },
        castbar = {
            type = "group", order = 11, name = "Cast Bar",
            args = {
                enabled = { type = "toggle", order = 1, name = "Enable cast bar" },
                height = {
                    type = "range", order = 2, name = "Cast bar height",
                    min = 10, max = 32, step = 1,
                },
            },
        },
        auras = {
            type = "group", order = 12, name = "Auras",
            args = {
                enabled = { type = "toggle", order = 1, name = "Show CC/immunity overlay" },
            },
        },
        trinket = {
            type = "group", order = 13, name = "Trinket",
            args = {
                enabled = { type = "toggle", order = 1, name = "Track PvP trinket" },
                size = { type = "range", order = 2, name = "Icon size", min = 20, max = 64, step = 2 },
            },
        },
        dr = {
            type = "group", order = 14, name = "Diminishing Returns",
            args = {
                enabled = { type = "toggle", order = 1, name = "Track diminishing returns" },
                position = {
                    type = "select", order = 2, name = "Position",
                    desc = "Which side of the frame the DR icons grow from.",
                    values = { left = "Left of frame", right = "Right of frame" },
                },
                iconSize = { type = "range", order = 3, name = "Icon size", min = 14, max = 44, step = 2 },
            },
        },
        cooldowns = {
            type = "group", order = 15, name = "Cooldowns",
            args = {
                enabled = { type = "toggle", order = 1, name = "Track enemy cooldowns" },
                position = {
                    type = "select", order = 2, name = "Position",
                    desc = "Below frame tucks the icons under the cast bar (or directly under the bars when the cast bar is off). Right of frame lines them up after the trinket - avoid combining with DR icons on the right.",
                    values = { below = "Below frame", right = "Right of frame" },
                },
                iconSize = { type = "range", order = 3, name = "Icon size", min = 14, max = 44, step = 2 },
            },
        },
        announcer = {
            type = "group", order = 16, name = "Announcer",
            args = {
                enabled = { type = "toggle", order = 1, name = "Enable announcer" },
                useTTS = { type = "toggle", order = 2, name = "Use text-to-speech" },
                voice = {
                    type = "select", order = 2.5, name = "Voice",
                    desc = "Which installed text-to-speech voice to use. Automatic tries them until one works.",
                    values = function()
                        local t = { auto = "Automatic" }
                        for _, v in ipairs(AA.GetTtsVoices()) do
                            t[tostring(v.voiceID)] = v.name or ("Voice " .. tostring(v.voiceID))
                        end
                        return t
                    end,
                },
                trinket = { type = "toggle", order = 3, name = "Announce trinket" },
                drink = { type = "toggle", order = 4, name = "Announce drinking" },
                casts = { type = "toggle", order = 5, name = "Announce CC casts" },
                resurrect = { type = "toggle", order = 6, name = "Announce resurrects" },
                lowHealth = { type = "toggle", order = 7, name = "Announce low health" },
                lowHealthThreshold = {
                    type = "range", order = 8, name = "Low health threshold",
                    min = 0.1, max = 0.5, step = 0.05, isPercent = true,
                },
                test = {
                    type = "execute", order = 9, name = "Test voice",
                    desc = "Plays a sample announcement so you can hear the text-to-speech voice and volume.",
                    func = function()
                        local voices = AA.GetTtsVoices()
                        if #voices == 0 then
                            addon:Print("No text-to-speech voices found. Check Options > Accessibility > Text-to-Speech in WoW, and that Windows has a voice installed.")
                        else
                            for _, v in ipairs(voices) do
                                addon:Print(("Voice %d: %s"):format(v.voiceID or -1, v.name or "?"))
                            end
                        end
                        AA.Announcer:Speak("Enemy trinket used", true)
                    end,
                },
            },
        },
        recorder = {
            type = "group", order = 17, name = "Match Recorder",
            args = {
                enabled = { type = "toggle", order = 1, name = "Record arena matches" },
                count = {
                    type = "description", order = 2,
                    name = function()
                        return ("\nMatches stored: %d\nData is written to SavedVariables\\ArenaArmory.lua on logout or /reload for the Arena Armory desktop app.")
                            :format(AA.Recorder and AA.Recorder:GetMatchCount() or 0)
                    end,
                },
            },
        },
        analytics = {
            type = "group", order = 17.5, name = "Analytics",
            args = {
                enabled = { type = "toggle", order = 1, name = "Enable in-game analytics" },
                announceComp = {
                    type = "toggle", order = 2, name = "Announce record vs comp", width = "full",
                    desc = "When all opponents are identified, shows your win-loss record against that comp (e.g. \"You are 2-1 vs Rogue/Priest\").",
                },
                postMatch = {
                    type = "toggle", order = 3, name = "Post-match summary", width = "full",
                    desc = "After each recorded game, prints your updated record vs that comp and today's win-loss.",
                },
                open = {
                    type = "execute", order = 4, name = "Open stats panel",
                    desc = "Your records by bracket, recent matches with rating changes, comps, and partners. Also: /aa stats",
                    func = function() AA.Analytics:Toggle() end,
                },
            },
        },
        website = {
            type = "group", order = 18, name = "Website",
            args = {
                about = {
                    type = "description", order = 1, fontSize = "medium",
                    name = "Your recorded matches sync to arenaarmory.com via the desktop app: winrates by comp, map, and bracket, per-match scoreboards, and event timelines. Look up any character's public arena history, gear, and talents.\n",
                },
                open = {
                    type = "execute", order = 2, name = "arenaarmory.com",
                    desc = "Shows a copyable link to the website.",
                    func = function() AA.ShowCopyDialog(AA.SITE_URL, "arenaarmory.com") end,
                },
                matches = {
                    type = "execute", order = 3, name = "My match history",
                    desc = "Shows a copyable link to your match history page.",
                    func = function() AA.ShowCopyDialog(AA.SITE_URL .. "/matches", "Your matches on arenaarmory.com") end,
                },
                lookup = {
                    type = "input", order = 4, name = "Look up a character",
                    desc = "Name or Name-Realm. Builds an armory link for any player (also: shift-click an enemy frame, or /aa lookup).",
                    get = function() return "" end,
                    set = function(_, v)
                        if v and v:trim() ~= "" then AA.LookupName(v:trim()) end
                    end,
                },
            },
        },
    },
}

AceConfig:RegisterOptionsTable("ArenaArmory", options)
AceConfigDialog:SetDefaultSize("ArenaArmory", 640, 520)

addon:RegisterChatCommand("aa", function(input)
    input = (input or ""):trim()
    local command, rest = input:match("^(%S*)%s*(.-)$")
    command = (command or ""):lower()
    if command == "test" then
        AA.TestMode:Toggle()
    elseif command == "lock" then
        AA.db.profile.locked = not AA.db.profile.locked
        AA.Frames:UpdateLockState()
        addon:Print(AA.db.profile.locked and "Frames locked." or "Frames unlocked - drag the green anchor.")
    elseif command == "matches" then
        addon:Print(("Matches stored: %d"):format(AA.Recorder:GetMatchCount()))
    elseif command == "stats" then
        AA.Analytics:Toggle()
    elseif command == "web" then
        AA.ShowCopyDialog(AA.SITE_URL, "arenaarmory.com")
    elseif command == "lookup" then
        if rest ~= "" then
            AA.LookupName(rest)
        elseif UnitExists("target") and UnitIsPlayer("target") then
            AA.LookupUnit("target")
        else
            addon:Print("Usage: /aa lookup Name (or Name-Realm), or target a player first.")
        end
    else
        AceConfigDialog:Open("ArenaArmory")
    end
end)
addon:RegisterChatCommand("arenaarmory", function() AceConfigDialog:Open("ArenaArmory") end)
