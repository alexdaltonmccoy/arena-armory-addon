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
                trackRacial = {
                    type = "toggle", order = 2, name = "Track racial CC break", width = "full",
                    desc = "Will of the Forsaken doesn't share the trinket cooldown in TBC, so it gets its own icon to the right of the medallion (appears on first use).",
                },
                size = { type = "range", order = 3, name = "Icon size", min = 20, max = 64, step = 2 },
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
                useSounds = {
                    type = "toggle", order = 2, name = "Play voice clips",
                    desc = "GladiatorlosSA-style callouts from Media/Voice/*.ogg (recommended).",
                },
                channel = {
                    type = "select", order = 2.1, name = "Sound channel",
                    desc = "Master ignores most volume mixers except the master slider.",
                    values = {
                        Master = "Master",
                        SFX = "Sound Effects",
                        Dialog = "Dialog",
                    },
                },
                useTTS = {
                    type = "toggle", order = 2.2, name = "Also use text-to-speech",
                    desc = "Optional. Anniversary TTS is unreliable; voice clips are the primary channel.",
                },
                voice = {
                    type = "select", order = 2.3, name = "TTS voice",
                    desc = "Only used when text-to-speech is enabled.",
                    values = function()
                        local t = { auto = "Automatic" }
                        for _, v in ipairs(AA.GetTtsVoices()) do
                            t[tostring(v.voiceID)] = v.name or ("Voice " .. tostring(v.voiceID))
                        end
                        return t
                    end,
                },
                alertSound = {
                    type = "toggle", order = 2.4, name = "Beep if clip missing",
                    desc = "Play a raid-warning beep when a voice clip fails and TTS is off.",
                },
                raidWarning = {
                    type = "toggle", order = 2.5, name = "Raid warning text",
                    desc = "Also flash the callout as a raid warning on screen.",
                },
                chatCallout = {
                    type = "select", order = 2.6, name = "Chat callouts",
                    desc = "Party chat for majors only (trinket, drinking, walls, lust, innervate, res). Other announces stay voice/raid-warning — no chat spam.",
                    values = {
                        off = "Off",
                        self = "Self chat (all announces)",
                        party = "Party chat (majors only)",
                    },
                },
                trinket = { type = "toggle", order = 3, name = "Announce trinket" },
                drink = { type = "toggle", order = 4, name = "Announce drinking" },
                casts = { type = "toggle", order = 5, name = "Announce CC",
                    desc = "Polymorph, Blind, Fear, Cyclone, etc." },
                cooldowns = { type = "toggle", order = 5.5, name = "Announce major cooldowns",
                    desc = "Bubble, Ice Block, Cloak, Evasion, NS, Grounding, etc." },
                interrupts = { type = "toggle", order = 5.7, name = "Announce interrupts",
                    desc = "Kick, Pummel, Counterspell, Spell Lock (noisy; off by default)." },
                resurrect = { type = "toggle", order = 6, name = "Announce resurrects" },
                lowHealth = { type = "toggle", order = 7, name = "Announce low health" },
                lowHealthThreshold = {
                    type = "range", order = 8, name = "Low health threshold",
                    min = 0.1, max = 0.5, step = 0.05, isPercent = true,
                },
                test = {
                    type = "execute", order = 9, name = "Test voice",
                    desc = "Plays the trinket voice clip (and TTS if enabled).",
                    func = function()
                        AA.Announcer:Announce("trinket", "Trinket", true)
                    end,
                },
                debugDump = {
                    type = "execute", order = 10, name = "Dump announcer status",
                    desc = "Prints announcer state to chat. Also: /aa announcer",
                    func = function() AA.Announcer:DumpStatus() end,
                },
                debugToggle = {
                    type = "execute", order = 11, name = "Toggle announcer debug",
                    desc = "Chat-traces every announce attempt / miss. Also: /aa announcer debug",
                    func = function() AA.Announcer:SetDebug(not AA.Announcer.debug) end,
                },
            },
        },
        partyMark = {
            type = "group", order = 16.5, name = "Party Marks",
            args = {
                enabled = {
                    type = "toggle", order = 1, name = "Auto-mark party by class in arena",
                    desc = "Assigns raid target icons by class. Cleared when you leave the arena.",
                    width = "full",
                },
                announce = {
                    type = "toggle", order = 2, name = "Announce marks in party chat",
                    desc = "Sends \"[Arena Armory] Marked party: {rt} Name, …\" when marks are applied.",
                    width = "full",
                },
                hint = {
                    type = "description", order = 3,
                    name = "\nPick a raid icon per class. Defaults follow class colors "
                        .. "(orange Circle = Druid, Skull = Warrior, etc.). "
                        .. "If two classes share an icon, the second party member gets the next free mark. "
                        .. "Also: /aa marks",
                },
                classIcons = {
                    type = "group", order = 4, name = "Class icons", inline = true,
                    args = (function()
                        local iconValues = {
                            [1] = "1 Star (yellow)",
                            [2] = "2 Circle (orange)",
                            [3] = "3 Diamond (purple)",
                            [4] = "4 Triangle (green)",
                            [5] = "5 Moon",
                            [6] = "6 Square (blue)",
                            [7] = "7 Cross",
                            [8] = "8 Skull",
                        }
                        local classNames = {
                            WARRIOR = "Warrior",
                            PALADIN = "Paladin",
                            HUNTER = "Hunter",
                            ROGUE = "Rogue",
                            PRIEST = "Priest",
                            SHAMAN = "Shaman",
                            MAGE = "Mage",
                            WARLOCK = "Warlock",
                            DRUID = "Druid",
                        }
                        local order = {
                            "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST",
                            "SHAMAN", "MAGE", "WARLOCK", "DRUID",
                        }
                        local args = {}
                        for i, class in ipairs(order) do
                            args[class] = {
                                type = "select",
                                order = i,
                                name = classNames[class],
                                values = iconValues,
                                get = function()
                                    local map = AA.db.profile.partyMark.classIcons
                                    if type(map) ~= "table" or type(map[class]) ~= "number" then
                                        return AA.DEFAULT_CLASS_MARKS[class]
                                    end
                                    return map[class]
                                end,
                                set = function(_, value)
                                    local cfg = AA.db.profile.partyMark
                                    if type(cfg.classIcons) ~= "table" then
                                        cfg.classIcons = {}
                                    end
                                    cfg.classIcons[class] = value
                                    if AA.inArena and AA.PartyMark then
                                        AA.PartyMark.announcedThisArena = false
                                        AA.PartyMark:Apply()
                                    end
                                end,
                            }
                        end
                        return args
                    end)(),
                },
                reset = {
                    type = "execute", order = 5, name = "Reset to class-color defaults",
                    func = function()
                        AA.PartyMark:ResetClassIcons()
                        addon:Print("Party mark class icons reset to class-color defaults.")
                        if AA.inArena then
                            AA.PartyMark.announcedThisArena = false
                            AA.PartyMark:Apply()
                        end
                    end,
                },
                force = {
                    type = "execute", order = 6, name = "Apply marks now",
                    desc = "Force a mark pass in the current arena (also: /aa marks).",
                    func = function() AA.PartyMark:ForceApply() end,
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
    elseif command == "currency" then
        AA.Currency:DebugPrint()
    elseif command == "ratings" then
        AA.Recorder:DebugRatings()
    elseif command == "announcer" or command == "aaudio" then
        local sub = (rest or ""):lower():match("^(%S*)") or ""
        if sub == "debug" or sub == "on" then
            AA.Announcer:SetDebug(true)
        elseif sub == "off" then
            AA.Announcer:SetDebug(false)
        elseif sub == "test" then
            AA.Announcer:Announce("trinket", "Trinket", true)
        elseif sub == "toggle" then
            AA.Announcer:SetDebug(not AA.Announcer.debug)
        else
            AA.Announcer:DumpStatus()
            addon:Print("Also: /aa announcer debug | off | test")
        end
    elseif command == "stats" then
        AA.Analytics:Toggle()
    elseif command == "marks" or command == "mark" then
        AA.PartyMark:ForceApply()
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
