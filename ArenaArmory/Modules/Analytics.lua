-- In-game analytics computed live from the ArenaArmoryMatches SavedVariable.
-- The match table is in memory the moment the Recorder finalizes a game, so
-- records update between matches without any /reload or desktop round trip:
--   * on arena entry, once all opponent classes are known, announce your
--     record vs that comp ("You are 2-1 vs Rogue/Priest")
--   * after each recorded match, print the updated record
--   * /aa stats opens a panel: per-bracket records, recent games with rating
--     changes, comp records, and partner records.
local _, AA = ...
local addon = AA.addon

local Analytics = addon:NewModule("Analytics", "AceEvent-3.0")
AA.Analytics = Analytics

local GOLD  = "|cffe6c87d"
local GREEN = "|cff5fd48a"
local RED   = "|cffff6b6b"
local GRAY  = "|cff9d9d9d"

local function ClassColorCode(token)
    local c = token and RAID_CLASS_COLORS and RAID_CLASS_COLORS[token]
    if c then
        if c.colorStr then return "|c" .. c.colorStr end
        if c.r then
            return ("|cff%02x%02x%02x"):format(c.r * 255, c.g * 255, c.b * 255)
        end
    end
    return "|cffffffff"
end

local function LocClass(token)
    return (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[token]) or token or "?"
end

-------------------------------------------------------------------------------
-- Comp keys
-------------------------------------------------------------------------------

-- Canonical key for a set of class tokens: sorted, joined with "+", so
-- Rogue/Priest and Priest/Rogue are the same comp.
local function CompKey(tokens)
    if #tokens == 0 then return nil end
    local sorted = {}
    for _, t in ipairs(tokens) do table.insert(sorted, t) end
    table.sort(sorted)
    return table.concat(sorted, "+")
end

local function CompLabel(key)
    if not key then return "?" end
    local parts = {}
    for token in key:gmatch("[^+]+") do
        table.insert(parts, ClassColorCode(token) .. LocClass(token) .. "|r")
    end
    return table.concat(parts, "/")
end

-- Comp key for a recorded match's enemy team; nil if any class is unknown
-- (that match can't be attributed to a comp).
local function MatchCompKey(m)
    if type(m.enemyTeam) ~= "table" or #m.enemyTeam == 0 then return nil end
    local tokens = {}
    for _, e in ipairs(m.enemyTeam) do
        if not e.class then return nil end
        table.insert(tokens, e.class)
    end
    return CompKey(tokens)
end

-------------------------------------------------------------------------------
-- Stats aggregation
-------------------------------------------------------------------------------

-- The SavedVariables file is account-wide; only this character's games count.
local function PlayerMatches()
    local list = {}
    if not ArenaArmoryMatches or type(ArenaArmoryMatches.matches) ~= "table" then
        return list
    end
    local me = AA.StripRealm(UnitName("player"))
    local realm = GetRealmName and GetRealmName() or ""
    for _, m in ipairs(ArenaArmoryMatches.matches) do
        local p = m.player
        if p and p.name == me and (not p.realm or p.realm == "" or p.realm == realm) then
            table.insert(list, m)
        end
    end
    return list
end

-- Battlefield side we were on: recorded directly, or implied by winner+result.
local function OurSide(m)
    if m.ourSide ~= nil then return m.ourSide end
    if (m.winner == 0 or m.winner == 1) and (m.result == "win" or m.result == "loss") then
        if m.result == "win" then return m.winner end
        return 1 - m.winner
    end
    return nil
end

local function RatingDelta(m)
    local side = OurSide(m)
    if side == nil or type(m.ratings) ~= "table" then return nil, nil end
    local r = m.ratings[side]
    if type(r) ~= "table" then return nil, nil end
    local newR = tonumber(r.newRating)
    local oldR = tonumber(r.oldRating)
    if not newR or newR <= 0 then return nil, nil end
    return newR, oldR and (newR - oldR) or nil
end

local function Tally(bucket, won)
    if won then bucket.w = bucket.w + 1 else bucket.l = bucket.l + 1 end
end

function Analytics:Build()
    local ms = PlayerMatches()
    local stats = {
        count = #ms,
        total = { w = 0, l = 0 },
        today = { w = 0, l = 0 },
        brackets = {},  -- [size] = { w, l, rating }
        comps = {},     -- [key]  = { w, l, key }
        partners = {},  -- [name] = { w, l, name, class }
        recent = {},    -- newest first, capped by the panel
    }

    local t = date("*t")
    t.hour, t.min, t.sec = 0, 0, 0
    local todayStart = time(t)

    local me = AA.StripRealm(UnitName("player"))

    for _, m in ipairs(ms) do
        local decided = (m.result == "win" or m.result == "loss")
        if decided then
            local won = (m.result == "win")
            Tally(stats.total, won)
            if (m.startedAt or 0) >= todayStart then
                Tally(stats.today, won)
            end

            local size = m.bracket or 0
            if size > 0 then
                local b = stats.brackets[size]
                if not b then
                    b = { w = 0, l = 0 }
                    stats.brackets[size] = b
                end
                Tally(b, won)
                -- Matches are stored chronologically; the last rated game's
                -- newRating is the current rating for that bracket.
                local rating = RatingDelta(m)
                if rating then b.rating = rating end
            end

            local key = MatchCompKey(m)
            if key then
                local c = stats.comps[key]
                if not c then
                    c = { w = 0, l = 0, key = key }
                    stats.comps[key] = c
                end
                Tally(c, won)
            end

            if type(m.team) == "table" then
                for _, p in ipairs(m.team) do
                    if p.name and p.name ~= me then
                        local pr = stats.partners[p.name]
                        if not pr then
                            pr = { w = 0, l = 0, name = p.name, class = p.class }
                            stats.partners[p.name] = pr
                        end
                        Tally(pr, won)
                    end
                end
            end
        end
    end

    for i = #ms, 1, -1 do
        table.insert(stats.recent, ms[i])
    end

    return stats
end

function Analytics:RecordVsComp(key)
    if not key then return 0, 0 end
    local w, l = 0, 0
    for _, m in ipairs(PlayerMatches()) do
        if MatchCompKey(m) == key then
            if m.result == "win" then w = w + 1
            elseif m.result == "loss" then l = l + 1 end
        end
    end
    return w, l
end

-------------------------------------------------------------------------------
-- Formatting
-------------------------------------------------------------------------------

local function Pct(w, l)
    local n = w + l
    if n == 0 then return "-" end
    return ("%d%%"):format(math.floor(w / n * 100 + 0.5))
end

local function Record(w, l)
    return ("%s%d|r-%s%d|r (%s)"):format(GREEN, w, RED, l, Pct(w, l))
end

local function FmtDelta(delta)
    if not delta then return "" end
    if delta >= 0 then return ("  %s+%d|r"):format(GREEN, delta) end
    return ("  %s%d|r"):format(RED, delta)
end

local function FmtDuration(s)
    if not s then return "" end
    return ("%d:%02d"):format(math.floor(s / 60), s % 60)
end

-------------------------------------------------------------------------------
-- Live announcements
-------------------------------------------------------------------------------

-- Once every expected opponent's class is known, announce the record vs that
-- comp. Stealth can delay this past the gates; announce as soon as complete.
function Analytics:TryAnnounceComp()
    if self.compAnnounced or not AA.inArena or AA.testMode then return end
    local cfg = AA.db.profile.analytics
    if not cfg.enabled or not cfg.announceComp then return end

    local expected = 0
    if GetBattlefieldStatus then
        for i = 1, (GetMaxBattlefieldID and GetMaxBattlefieldID() or 3) do
            local status, _, _, _, _, teamSize = GetBattlefieldStatus(i)
            if status == "active" and teamSize and teamSize > 0 then
                expected = teamSize
                break
            end
        end
    end
    -- Skirmishes report teamSize 0; enemy team size matches our own group.
    if expected == 0 then
        expected = math.max(GetNumGroupMembers and GetNumGroupMembers() or 1, 1)
    end

    local tokens = {}
    for i = 1, expected do
        local token = AA.unitClass["arena" .. i]
        if not token then return end -- someone still unseen; try again later
        table.insert(tokens, token)
    end

    self.compAnnounced = true
    local key = CompKey(tokens)
    local w, l = self:RecordVsComp(key)
    local label = CompLabel(key)
    local msg
    if w + l > 0 then
        msg = ("You are %s vs %s"):format(Record(w, l), label)
    else
        msg = ("First time facing %s"):format(label)
    end
    addon:Print(msg)
    if RaidNotice_AddMessage and RaidWarningFrame then
        RaidNotice_AddMessage(RaidWarningFrame, msg, ChatTypeInfo["RAID_WARNING"])
    end
end

function Analytics:OnArenaJoined()
    self.compAnnounced = false
    self:TryAnnounceComp()
end

function Analytics:OnOpponentUpdate()
    self:TryAnnounceComp()
end

function Analytics:OnMatchRecorded(_, match)
    local cfg = AA.db.profile.analytics
    if not cfg.enabled then return end

    if cfg.postMatch then
        local key = MatchCompKey(match)
        local s = self:Build()
        local parts = {}
        if key then
            local w, l = self:RecordVsComp(key)
            table.insert(parts, ("Record vs %s: %s."):format(CompLabel(key), Record(w, l)))
        end
        table.insert(parts, ("Today: %s."):format(Record(s.today.w, s.today.l)))
        table.insert(parts, "/aa stats for details.")
        addon:Print(table.concat(parts, " "))
    end

    -- Live refresh if the panel is open between games.
    if self.panel and self.panel:IsShown() then
        self:Populate()
    end
end

-------------------------------------------------------------------------------
-- Stats panel (/aa stats)
-------------------------------------------------------------------------------

local PANEL_WIDTH = 500
local PAD = 16
local LINE_HEIGHT = 15

local MAX_RECENT = 8
local MAX_COMPS = 8
local MAX_PARTNERS = 6

function Analytics:EnsurePanel()
    if self.panel then return self.panel end

    local p = CreateFrame("Frame", "ArenaArmoryStatsPanel", UIParent,
        BackdropTemplateMixin and "BackdropTemplate" or nil)
    p:SetSize(PANEL_WIDTH, 400)
    p:SetPoint("CENTER")
    p:SetFrameStrata("HIGH")
    p:SetMovable(true)
    p:EnableMouse(true)
    p:RegisterForDrag("LeftButton")
    p:SetScript("OnDragStart", p.StartMoving)
    p:SetScript("OnDragStop", p.StopMovingOrSizing)
    p:SetClampedToScreen(true)
    if p.SetBackdrop then
        p:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        p:SetBackdropColor(0.05, 0.045, 0.03, 0.95)
        p:SetBackdropBorderColor(0.9, 0.78, 0.49, 0.35)
    end

    p.title = p:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    p.title:SetPoint("TOPLEFT", PAD, -12)
    p.title:SetText(GOLD .. "Arena Armory|r Stats")

    local close = CreateFrame("Button", nil, p, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)

    p.lines = {}

    -- Esc closes the panel like a normal WoW window.
    tinsert(UISpecialFrames, "ArenaArmoryStatsPanel")

    self.panel = p
    return p
end

function Analytics:Populate()
    local p = self:EnsurePanel()
    local s = self:Build()

    for _, fs in ipairs(p.lines) do fs:Hide() end
    local n = 0
    local y = -40

    local function Add(text, header)
        n = n + 1
        local fs = p.lines[n]
        if not fs then
            fs = p:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            fs:SetJustifyH("LEFT")
            fs:SetWidth(PANEL_WIDTH - PAD * 2)
            fs:SetWordWrap(false)
            p.lines[n] = fs
        end
        fs:SetFontObject(header and "GameFontNormal" or "GameFontHighlightSmall")
        if header then y = y - 7 end
        fs:ClearAllPoints()
        fs:SetPoint("TOPLEFT", PAD, y)
        fs:SetText(text)
        fs:Show()
        y = y - LINE_HEIGHT
    end

    local me = AA.StripRealm(UnitName("player"))
    if s.count == 0 then
        Add(("%s%s|r has no recorded matches yet."):format(GOLD, me))
        Add(GRAY .. "Play arenas with the recorder enabled, then check back." .. "|r")
    else
        Add(("%s%s|r  ·  %d matches  ·  %s all-time  ·  %s today")
            :format(GOLD, me, s.count, Record(s.total.w, s.total.l), Record(s.today.w, s.today.l)))

        local sizes = {}
        for size in pairs(s.brackets) do table.insert(sizes, size) end
        table.sort(sizes)
        if #sizes > 0 then
            Add(GOLD .. "Brackets" .. "|r", true)
            for _, size in ipairs(sizes) do
                local b = s.brackets[size]
                local rating = b.rating and ("  ·  rating %d"):format(b.rating) or ""
                Add(("  %dv%d: %s%s"):format(size, size, Record(b.w, b.l), rating))
            end
        end

        if #s.recent > 0 then
            Add(GOLD .. "Recent matches" .. "|r", true)
            for i = 1, math.min(#s.recent, MAX_RECENT) do
                local m = s.recent[i]
                local letter = m.result == "win" and (GREEN .. "W|r")
                    or m.result == "loss" and (RED .. "L|r")
                    or (GRAY .. "-|r")
                local key = MatchCompKey(m)
                local _, delta = RatingDelta(m)
                Add(("  %s  %s  %s  vs %s  %s%s"):format(
                    letter,
                    date("%m/%d", m.startedAt or 0),
                    m.bracket and (m.bracket .. "v" .. m.bracket) or "?",
                    key and CompLabel(key) or (GRAY .. "unknown comp|r"),
                    GRAY .. FmtDuration(m.durationSeconds) .. "|r",
                    FmtDelta(delta)))
            end
        end

        local comps = {}
        for _, c in pairs(s.comps) do table.insert(comps, c) end
        table.sort(comps, function(a, b)
            if a.w + a.l ~= b.w + b.l then return a.w + a.l > b.w + b.l end
            return a.key < b.key
        end)
        if #comps > 0 then
            Add(GOLD .. "Vs comps" .. "|r", true)
            for i = 1, math.min(#comps, MAX_COMPS) do
                local c = comps[i]
                Add(("  %s  %s"):format(Record(c.w, c.l), CompLabel(c.key)))
            end
        end

        local partners = {}
        for _, pr in pairs(s.partners) do table.insert(partners, pr) end
        table.sort(partners, function(a, b)
            if a.w + a.l ~= b.w + b.l then return a.w + a.l > b.w + b.l end
            return a.name < b.name
        end)
        if #partners > 0 then
            Add(GOLD .. "With partners" .. "|r", true)
            for i = 1, math.min(#partners, MAX_PARTNERS) do
                local pr = partners[i]
                Add(("  %s  %s%s|r"):format(
                    Record(pr.w, pr.l), ClassColorCode(pr.class), pr.name))
            end
        end
    end

    Add(GRAY .. "Full analytics, rating charts, and event timelines: arenaarmory.com" .. "|r", true)

    p:SetHeight(-y + PAD)
end

function Analytics:Toggle()
    local p = self:EnsurePanel()
    if p:IsShown() then
        p:Hide()
    else
        self:Populate()
        p:Show()
    end
end

-------------------------------------------------------------------------------
-- Module lifecycle
-------------------------------------------------------------------------------

function Analytics:OnEnable()
    self:RegisterMessage("AA_ARENA_JOINED", "OnArenaJoined")
    self:RegisterMessage("AA_OPPONENT_UPDATE", "OnOpponentUpdate")
    self:RegisterMessage("AA_MATCH_RECORDED", "OnMatchRecorded")
end
