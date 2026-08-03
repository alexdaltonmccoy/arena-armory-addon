-- In arena, auto-assign raid target icons to party members by class.
local _, AA = ...
local addon = AA.addon

local PartyMark = addon:NewModule("PartyMark", "AceEvent-3.0", "AceTimer-3.0")
AA.PartyMark = PartyMark

-- Default raid icons by class color (rt1–rt8). Nine TBC classes / eight icons:
-- Mage + Shaman both blue → share Square; second one gets next free icon.
AA.DEFAULT_CLASS_MARKS = {
    ROGUE   = 1, -- Star (yellow)
    DRUID   = 2, -- Circle (orange)
    WARLOCK = 3, -- Diamond (purple)
    HUNTER  = 4, -- Triangle (green)
    PRIEST  = 5, -- Moon (white)
    MAGE    = 6, -- Square (blue)
    SHAMAN  = 6, -- Square (blue)
    PALADIN = 7, -- Cross (red / pink)
    WARRIOR = 8, -- Skull
}

local CLASS_ORDER = {
    "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST",
    "SHAMAN", "MAGE", "WARLOCK", "DRUID",
}

AA.RAID_ICON_NAMES = {
    [1] = "Star",
    [2] = "Circle",
    [3] = "Diamond",
    [4] = "Triangle",
    [5] = "Moon",
    [6] = "Square",
    [7] = "Cross",
    [8] = "Skull",
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

function PartyMark:GetClassIcons()
    local cfg = AA.db and AA.db.profile and AA.db.profile.partyMark
    local map = cfg and cfg.classIcons
    if type(map) ~= "table" then
        return AA.DEFAULT_CLASS_MARKS
    end
    return map
end

function PartyMark:PreferredIcon(classToken)
    if not classToken then return nil end
    local map = self:GetClassIcons()
    local icon = map[classToken]
    if type(icon) ~= "number" or icon < 1 or icon > 8 then
        icon = AA.DEFAULT_CLASS_MARKS[classToken]
    end
    return icon
end

--- Copy into a profile-owned table so we never mutate AceDB shared defaults.
function PartyMark:EnsureOwnedClassIcons()
    local cfg = AA.db.profile.partyMark
    local src = cfg.classIcons
    local owned = {}
    for class, defaultIcon in pairs(AA.DEFAULT_CLASS_MARKS) do
        local v = type(src) == "table" and src[class]
        if type(v) == "number" and v >= 1 and v <= 8 then
            owned[class] = v
        else
            owned[class] = defaultIcon
        end
    end
    cfg.classIcons = owned
end

function PartyMark:ResetClassIcons()
    local cfg = AA.db.profile.partyMark
    local owned = {}
    for class, icon in pairs(AA.DEFAULT_CLASS_MARKS) do
        owned[class] = icon
    end
    cfg.classIcons = owned
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
            local _, classToken = UnitClass(unit)
            table.insert(assignments, {
                unit = unit,
                icon = icon,
                name = name,
                class = classToken,
            })
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

function PartyMark:CancelApplyTimers()
    if self.applyTimers then
        for _, t in ipairs(self.applyTimers) do
            self:CancelTimer(t, true)
        end
    end
    self.applyTimers = {}
    if self.applyTimer then
        self:CancelTimer(self.applyTimer, true)
        self.applyTimer = nil
    end
end

function PartyMark:ScheduleApplyPasses()
    self:CancelApplyTimers()
    -- Several passes: roster/class can lag on zone-in; combat may block the first try.
    for _, delay in ipairs({ 0.5, 1.5, 3.0, 5.0, 8.0 }) do
        table.insert(self.applyTimers, self:ScheduleTimer("Apply", delay))
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
        end
        return
    end

    local party = CollectParty()
    if #party == 0 then return end

    local used = {}
    local changed = 0
    local failed = 0

    -- Pass 1: claim each unit's preferred class icon when free.
    local plan = {}
    for _, unit in ipairs(party) do
        local _, classToken = UnitClass(unit)
        local preferred = self:PreferredIcon(classToken)
        plan[#plan + 1] = { unit = unit, class = classToken, preferred = preferred }
    end

    for _, entry in ipairs(plan) do
        local icon = entry.preferred
        if icon and not used[icon] then
            local result = SetMark(entry.unit, icon)
            if result == "changed" or result == "unchanged" then
                used[icon] = true
                entry.done = true
                if result == "changed" then changed = changed + 1 end
            elseif result == "failed" then
                failed = failed + 1
            end
        end
    end

    -- Pass 2: anyone still unmarked gets the next free icon.
    for _, entry in ipairs(plan) do
        if not entry.done then
            local icon = nil
            for i = 1, 8 do
                if not used[i] then
                    icon = i
                    break
                end
            end
            if icon then
                local result = SetMark(entry.unit, icon)
                if result == "changed" or result == "unchanged" then
                    used[icon] = true
                    entry.done = true
                    if result == "changed" then changed = changed + 1 end
                elseif result == "failed" then
                    failed = failed + 1
                end
            end
        end
    end

    if changed > 0 then
        self:AnnounceMarks(ReadAssignments())
    end

    return changed, failed
end

function PartyMark:DumpStatus()
    local inArena = AA.inArena and true or false
    local party = CollectParty()
    addon:Print(("Party marks: enabled=%s inArena=%s party=%d combat=%s leader=%s")
        :format(
            tostring(AA.db.profile.partyMark.enabled),
            tostring(inArena),
            #party,
            tostring(InCombatLockdown and InCombatLockdown() or false),
            tostring(UnitIsGroupLeader and UnitIsGroupLeader("player") or false)
        ))
    for _, unit in ipairs(party) do
        local name = AA.StripRealm(UnitName(unit)) or unit
        local _, classToken = UnitClass(unit)
        local preferred = self:PreferredIcon(classToken)
        local current = GetRaidTargetIndex and GetRaidTargetIndex(unit) or 0
        addon:Print(("  %s (%s) prefer=%s(%s) current=%s(%s)")
            :format(
                name,
                classToken or "?",
                tostring(preferred),
                AA.RAID_ICON_NAMES[preferred] or "?",
                tostring(current or 0),
                AA.RAID_ICON_NAMES[current] or "none"
            ))
    end
end

function PartyMark:ForceApply()
    self.announcedThisArena = false
    if not AA.inArena then
        addon:Print("Party marks: not in arena — nothing to mark.")
        self:DumpStatus()
        return
    end
    local changed, failed = self:Apply()
    addon:Print(("Party marks: apply done (changed=%s failed=%s).")
        :format(tostring(changed or 0), tostring(failed or 0)))
    self:DumpStatus()
end

function PartyMark:OnRegen()
    if not AA.inArena then
        self.pending = nil
        self:UnregisterEvent("PLAYER_REGEN_ENABLED")
        return
    end
    self.pending = nil
    self:UnregisterEvent("PLAYER_REGEN_ENABLED")
    self:Apply()
end

function PartyMark:OnArenaJoined()
    self.announcedThisArena = false
    self.pending = nil
    self:ScheduleApplyPasses()
end

function PartyMark:OnArenaLeft()
    self.pending = nil
    self.announcedThisArena = false
    self:CancelApplyTimers()
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
    self.announcedThisArena = false
    self.applyTimers = {}
    self:EnsureOwnedClassIcons()
    self:RegisterMessage("AA_ARENA_JOINED", "OnArenaJoined")
    self:RegisterMessage("AA_ARENA_LEFT", "OnArenaLeft")
    self:RegisterEvent("GROUP_ROSTER_UPDATE", "OnRoster")
end

function PartyMark:OnDisable()
    self:CancelApplyTimers()
end

-- Exported for Options.lua dropdown order.
AA.PARTY_MARK_CLASS_ORDER = CLASS_ORDER
