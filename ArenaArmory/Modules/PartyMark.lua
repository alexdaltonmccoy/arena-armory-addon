-- In arena, auto-assign raid target icons to party members by class.
local _, AA = ...
local addon = AA.addon

local PartyMark = addon:NewModule("PartyMark", "AceEvent-3.0", "AceTimer-3.0")
AA.PartyMark = PartyMark

local CLASS_ICON = {
    ROGUE   = 1, -- Star
    WARRIOR = 2, -- Circle
    MAGE    = 3, -- Diamond
    HUNTER  = 4, -- Triangle
    PRIEST  = 5, -- Moon
    PALADIN = 6, -- Square
    SHAMAN  = 7, -- Cross
    WARLOCK = 8, -- Skull
    DRUID   = 4, -- Triangle (collision resolved below)
}

local ICON_RT = {
    [1] = "{rt1}", [2] = "{rt2}", [3] = "{rt3}", [4] = "{rt4}",
    [5] = "{rt5}", [6] = "{rt6}", [7] = "{rt7}", [8] = "{rt8}",
}

local markedUnits = {}
local announcedKey = nil -- avoid re-spamming the same mark set

local function CanMark()
    if type(SetRaidTarget) ~= "function" then return false end
    if InCombatLockdown and InCombatLockdown() then return false end
    return true
end

local function SetMark(unit, icon)
    if not UnitExists(unit) then return false end
    local current = GetRaidTargetIndex and GetRaidTargetIndex(unit)
    if current == icon then
        markedUnits[unit] = icon
        return true
    end
    if current and current ~= 0 and current ~= icon then
        pcall(SetRaidTarget, unit, 0)
    end
    if pcall(SetRaidTarget, unit, icon) then
        markedUnits[unit] = icon
        return true
    end
    return false
end

local function ClearUnit(unit)
    if UnitExists(unit) and GetRaidTargetIndex and GetRaidTargetIndex(unit) then
        pcall(SetRaidTarget, unit, 0)
    end
    markedUnits[unit] = nil
end

function PartyMark:ClearAll()
    for unit in pairs(markedUnits) do
        ClearUnit(unit)
    end
    wipe(markedUnits)
    ClearUnit("player")
    for i = 1, 4 do
        ClearUnit("party" .. i)
    end
    announcedKey = nil
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

function PartyMark:AnnounceMarks(assignments)
    local cfg = AA.db.profile.partyMark
    if not cfg.announce then return end
    if #assignments == 0 then return end

    table.sort(assignments, function(a, b) return a.icon < b.icon end)
    local parts = {}
    local keyParts = {}
    for _, a in ipairs(assignments) do
        table.insert(parts, ("%s %s"):format(ICON_RT[a.icon] or ("#" .. a.icon), a.name))
        table.insert(keyParts, a.name .. "=" .. a.icon)
    end
    local key = table.concat(keyParts, "|")
    if key == announcedKey then return end
    announcedKey = key

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
    local assignments = {}
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
        if icon and SetMark(unit, icon) then
            used[icon] = true
            local name = AA.StripRealm(UnitName(unit)) or unit
            table.insert(assignments, { unit = unit, icon = icon, name = name })
        end
    end

    self:AnnounceMarks(assignments)
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
    announcedKey = nil
    self:ScheduleTimer("Apply", 0.5)
    self:ScheduleTimer("Apply", 2)
end

function PartyMark:OnArenaLeft()
    self.pending = nil
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
    if AA.inArena then
        self:Apply()
    end
end

function PartyMark:OnEnable()
    self:RegisterMessage("AA_ARENA_JOINED", "OnArenaJoined")
    self:RegisterMessage("AA_ARENA_LEFT", "OnArenaLeft")
    self:RegisterEvent("GROUP_ROSTER_UPDATE", "OnRoster")
end
