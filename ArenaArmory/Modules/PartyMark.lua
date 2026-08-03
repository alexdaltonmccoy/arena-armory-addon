-- In arena, auto-assign raid target icons to party members by class.
local _, AA = ...
local addon = AA.addon

local PartyMark = addon:NewModule("PartyMark", "AceEvent-3.0", "AceTimer-3.0")
AA.PartyMark = PartyMark

-- Raid icons by class color (rt1–rt8). Nine TBC classes / eight icons:
-- Mage + Shaman both blue → share Square; second one gets next free icon.
local CLASS_ICON = {
    ROGUE   = 1, -- Star (yellow)
    DRUID   = 2, -- Circle (orange)
    WARLOCK = 3, -- Diamond (purple)
    HUNTER  = 4, -- Triangle (green)
    PRIEST  = 5, -- Moon (white)
    MAGE    = 6, -- Square (blue)
    SHAMAN  = 6, -- Square (blue) — collision resolved in Apply
    PALADIN = 7, -- Cross (red / pink)
    WARRIOR = 8, -- Skull
}

local ICON_RT = {
    [1] = "{rt1}", [2] = "{rt2}", [3] = "{rt3}", [4] = "{rt4}",
    [5] = "{rt5}", [6] = "{rt6}", [7] = "{rt7}", [8] = "{rt8}",
}

local function CanMark()
    if type(SetRaidTarget) ~= "function" then return false end
    if InCombatLockdown and InCombatLockdown() then return false end
    return true
end

--- SetRaidTarget toggles if called with the icon the unit already has.
--- Only call when the current index differs; never clear+reapply blindly.
local function SetMark(unit, icon)
    if not UnitExists(unit) or not icon then return "missing" end
    local current = GetRaidTargetIndex and GetRaidTargetIndex(unit) or nil
    if current == icon then
        return "unchanged"
    end
    pcall(SetRaidTarget, unit, icon)
    local final = GetRaidTargetIndex and GetRaidTargetIndex(unit) or nil
    -- Toggle edge case: call flipped it off — set once more.
    if final ~= icon then
        pcall(SetRaidTarget, unit, icon)
        final = GetRaidTargetIndex and GetRaidTargetIndex(unit) or nil
    end
    if final == icon then
        return "changed"
    end
    return "failed"
end

local function ClearUnit(unit)
    if not UnitExists(unit) then return end
    local current = GetRaidTargetIndex and GetRaidTargetIndex(unit)
    if current and current ~= 0 then
        pcall(SetRaidTarget, unit, 0)
        -- If toggle weirdness left it on, try again only if still marked.
        if GetRaidTargetIndex(unit) then
            pcall(SetRaidTarget, unit, 0)
        end
    end
end

function PartyMark:ClearAll()
    ClearUnit("player")
    for i = 1, 4 do
        ClearUnit("party" .. i)
    end
    self.announcedThisArena = false
end

local function CollectParty()
    local list = {}
    if UnitExists("player") then table.insert(list, "player") end
    for i = 1, 4 do
        local u = "party" .. i
        if UnitExists(u) then table.insert(list, u) end
    end
    return list
end

local function ReadAssignments()
    local assignments = {}
    for _, unit in ipairs(CollectParty()) do
        local icon = GetRaidTargetIndex and GetRaidTargetIndex(unit)
        if icon and icon > 0 then
            local name = AA.StripRealm(UnitName(unit)) or unit
            table.insert(assignments, { unit = unit, icon = icon, name = name })
        end
    end
    table.sort(assignments, function(a, b) return a.icon < b.icon end)
    return assignments
end

function PartyMark:AnnounceMarks(assignments)
    local cfg = AA.db.profile.partyMark
    if not cfg.announce then return end
    if self.announcedThisArena then return end
    if not assignments or #assignments == 0 then return end

    local parts = {}
    for _, a in ipairs(assignments) do
        table.insert(parts, ("%s %s"):format(ICON_RT[a.icon] or ("#" .. a.icon), a.name))
    end

    self.announcedThisArena = true
    local msg = "[Arena Armory] Marked party: " .. table.concat(parts, ", ")
    if not AA.SendGroupMessage(msg) and DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff66ccff" .. msg .. "|r")
    end
end

function PartyMark:Apply()
    if not AA.db.profile.partyMark.enabled then return end
    if not AA.inArena or AA.testMode then return end
    if not IsInGroup or not IsInGroup() then return end

    if not CanMark() then
        if not self.pending then
            self.pending = true
            self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnRegen")
            self.applyTimer = self:ScheduleTimer("ApplyDeferred", 1.5)
        end
        return
    end

    local used = {}
    local changed = 0
    for _, unit in ipairs(CollectParty()) do
        local _, classToken = UnitClass(unit)
        local preferred = classToken and CLASS_ICON[classToken] or nil
        local icon = preferred
        if not icon or used[icon] then
            icon = nil
            for i = 1, 8 do
                if not used[i] then
                    icon = i
                    break
                end
            end
        end
        if icon then
            local result = SetMark(unit, icon)
            if result == "changed" or result == "unchanged" then
                used[icon] = true
                if result == "changed" then
                    changed = changed + 1
                end
            end
        end
    end

    -- Announce once per arena, only after we actually set something new,
    -- and only from icons the client reports (not our intent table).
    if changed > 0 then
        self:AnnounceMarks(ReadAssignments())
    end
end

function PartyMark:ApplyDeferred()
    self.applyTimer = nil
    if CanMark() then
        self.pending = nil
        self:UnregisterEvent("PLAYER_REGEN_ENABLED")
        self:Apply()
    elseif AA.inArena then
        self.applyTimer = self:ScheduleTimer("ApplyDeferred", 1.5)
    else
        self.pending = nil
        self:UnregisterEvent("PLAYER_REGEN_ENABLED")
    end
end

function PartyMark:OnRegen()
    if not AA.inArena then
        self.pending = nil
        self:UnregisterEvent("PLAYER_REGEN_ENABLED")
        return
    end
    self.pending = nil
    self:UnregisterEvent("PLAYER_REGEN_ENABLED")
    if self.applyTimer then
        self:CancelTimer(self.applyTimer)
        self.applyTimer = nil
    end
    self:Apply()
end

function PartyMark:OnArenaJoined()
    self.announcedThisArena = false
    -- Single delayed pass so UnitClass/roster are ready (avoids wrong first icons).
    if self.applyTimer then
        self:CancelTimer(self.applyTimer)
    end
    self.applyTimer = self:ScheduleTimer("Apply", 1.5)
end

function PartyMark:OnArenaLeft()
    self.pending = nil
    self.announcedThisArena = false
    if self.applyTimer then
        self:CancelTimer(self.applyTimer)
        self.applyTimer = nil
    end
    self:UnregisterEvent("PLAYER_REGEN_ENABLED")
    if CanMark() then
        self:ClearAll()
    else
        self:RegisterEvent("PLAYER_REGEN_ENABLED", "ClearWhenSafe")
    end
end

function PartyMark:ClearWhenSafe()
    self:UnregisterEvent("PLAYER_REGEN_ENABLED")
    if CanMark() then
        self:ClearAll()
    end
end

function PartyMark:OnRoster()
    -- Fix marks if roster changes mid-arena; do not re-announce.
    if AA.inArena then
        self:Apply()
    end
end

function PartyMark:OnEnable()
    self.announcedThisArena = false
    self:RegisterMessage("AA_ARENA_JOINED", "OnArenaJoined")
    self:RegisterMessage("AA_ARENA_LEFT", "OnArenaLeft")
    self:RegisterEvent("GROUP_ROSTER_UPDATE", "OnRoster")
end
