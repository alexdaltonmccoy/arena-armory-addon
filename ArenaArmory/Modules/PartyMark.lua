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

--- Set once. Never double-call: SetRaidTarget toggles, so a second call undoes
--- the first when GetRaidTargetIndex lags (caused Skull↔Star thrashing).
local function SetMark(unit, icon)
    if not UnitExists(unit) or not icon then return "missing" end
    local current = GetRaidTargetIndex and GetRaidTargetIndex(unit) or nil
    if current == icon then
        return "unchanged"
    end
    pcall(SetRaidTarget, unit, icon)
    return "changed"
end

local function ClearUnit(unit)
    if not UnitExists(unit) then return end
    local current = GetRaidTargetIndex and GetRaidTargetIndex(unit)
    if current and current ~= 0 then
        pcall(SetRaidTarget, unit, 0)
    end
end

function PartyMark:ClearAll()
    ClearUnit("player")
    for i = 1, 4 do
        ClearUnit("party" .. i)
    end
    for i = 1, 5 do
        ClearUnit("raid" .. i)
    end
    self.announcedThisArena = false
    self.appliedThisArena = false
end

--- Anniversary prints "Party converted to Raid" in arena — use raidN when
--- IsInRaid(), otherwise partyN. Dedupe by GUID so player isn't listed twice.
local function CollectParty()
    local list, seen = {}, {}
    local function add(unit)
        if not unit or not UnitExists(unit) then return end
        local guid = UnitGUID and UnitGUID(unit)
        if guid then
            if seen[guid] then return end
            seen[guid] = true
        end
        table.insert(list, unit)
    end

    add("player")
    if IsInRaid and IsInRaid() then
        for i = 1, 5 do
            add("raid" .. i)
        end
    else
        for i = 1, 4 do
            add("party" .. i)
        end
    end
    return list
end

local function ExpectedGroupSize()
    local n = GetNumGroupMembers and GetNumGroupMembers() or 0
    if n > 0 then return n end
    return 1
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

--- True when every party member already has their preferred (or a unique) mark
--- and no SetRaidTarget call is needed.
function PartyMark:NeedsApply()
    local party = CollectParty()
    if #party == 0 then return false end

    local used = {}
    for _, unit in ipairs(party) do
        local _, classToken = UnitClass(unit)
        local preferred = self:PreferredIcon(classToken)
        local current = GetRaidTargetIndex and GetRaidTargetIndex(unit) or nil
        if not current or current == 0 then
            return true
        end
        if preferred and current == preferred then
            if used[current] then return true end
            used[current] = true
        else
            -- Wrong mark for class (and preferred is free or unused): re-apply.
            if preferred and not used[preferred] then
                local preferredTaken = false
                for _, u2 in ipairs(party) do
                    if u2 ~= unit and (GetRaidTargetIndex(u2) or 0) == preferred then
                        preferredTaken = true
                        break
                    end
                end
                if not preferredTaken then
                    return true
                end
            end
            if used[current] then return true end
            used[current] = true
        end
    end
    return false
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

--- Delay announce so raid conversion / partner zone-in can finish — otherwise
--- we print "Marked party: You" and skull the warrior a moment later.
function PartyMark:QueueAnnounce()
    if not AA.db.profile.partyMark.announce then return end
    if self.announcedThisArena then return end
    if self.announceTimer then
        self:CancelTimer(self.announceTimer, true)
    end
    self.announceWait = 0
    self.announceTimer = self:ScheduleTimer("FlushAnnounce", 1.25)
end

function PartyMark:FlushAnnounce()
    self.announceTimer = nil
    if self.announcedThisArena or not AA.inArena then return end

    local assignments = ReadAssignments()
    if #assignments == 0 then return end

    local expected = ExpectedGroupSize()
    self.announceWait = (self.announceWait or 0) + 1
    if expected > 1 and #assignments < expected and self.announceWait < 5 then
        self.announceTimer = self:ScheduleTimer("FlushAnnounce", 1.0)
        return
    end

    self:AnnounceMarks(assignments)
end

function PartyMark:CancelApplyTimers()
    if self.applyTimer then
        self:CancelTimer(self.applyTimer, true)
        self.applyTimer = nil
    end
    if self.rosterTimer then
        self:CancelTimer(self.rosterTimer, true)
        self.rosterTimer = nil
    end
    if self.announceTimer then
        self:CancelTimer(self.announceTimer, true)
        self.announceTimer = nil
    end
end

function PartyMark:ScheduleApply(delay)
    if self.applyTimer then
        self:CancelTimer(self.applyTimer, true)
        self.applyTimer = nil
    end
    self.applyTimer = self:ScheduleTimer("Apply", delay or 2.0)
end

function PartyMark:Apply()
    self.applyTimer = nil
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

    -- Idempotent: do not touch marks that are already correct.
    if self.appliedThisArena and not self:NeedsApply() then
        return
    end

    local party = CollectParty()
    if #party == 0 then return end

    local used = {}
    local changed = 0

    local plan = {}
    for _, unit in ipairs(party) do
        local _, classToken = UnitClass(unit)
        plan[#plan + 1] = {
            unit = unit,
            class = classToken,
            preferred = self:PreferredIcon(classToken),
        }
    end

    -- Pass 1: preferred class icons.
    for _, entry in ipairs(plan) do
        local icon = entry.preferred
        if icon and not used[icon] then
            local result = SetMark(entry.unit, icon)
            if result == "changed" or result == "unchanged" then
                used[icon] = true
                entry.done = true
                if result == "changed" then changed = changed + 1 end
            end
        end
    end

    -- Pass 2: leftovers get next free icon (only if still unmarked / wrong).
    for _, entry in ipairs(plan) do
        if not entry.done then
            local current = GetRaidTargetIndex and GetRaidTargetIndex(entry.unit) or nil
            if current and current > 0 and not used[current] then
                -- Keep an existing unique mark rather than thrashing.
                used[current] = true
                entry.done = true
            else
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
                    end
                end
            end
        end
    end

    self.appliedThisArena = true

    if changed > 0 or (#ReadAssignments() > 0 and not self.announcedThisArena) then
        self:QueueAnnounce()
    end

    return changed
end

function PartyMark:DumpStatus()
    local party = CollectParty()
    addon:Print(("Party marks: enabled=%s inArena=%s party=%d combat=%s needsApply=%s")
        :format(
            tostring(AA.db.profile.partyMark.enabled),
            tostring(AA.inArena and true or false),
            #party,
            tostring(InCombatLockdown and InCombatLockdown() or false),
            tostring(self:NeedsApply())
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
    self.appliedThisArena = false
    if not AA.inArena then
        addon:Print("Party marks: not in arena — nothing to mark.")
        self:DumpStatus()
        return
    end
    local changed = self:Apply()
    addon:Print(("Party marks: apply done (changed=%s)."):format(tostring(changed or 0)))
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
    self:ScheduleApply(0.5)
end

function PartyMark:OnArenaJoined()
    self.announcedThisArena = false
    self.appliedThisArena = false
    self.pending = nil
    -- One calm pass after roster/class settle — not a burst of re-applies.
    self:ScheduleApply(2.0)
end

function PartyMark:OnArenaLeft()
    self.pending = nil
    self.announcedThisArena = false
    self.appliedThisArena = false
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
    if not AA.inArena then return end
    -- Debounce spammy GROUP_ROSTER_UPDATE during queue/zone-in.
    if self.rosterTimer then
        self:CancelTimer(self.rosterTimer, true)
    end
    self.rosterTimer = self:ScheduleTimer(function()
        self.rosterTimer = nil
        if AA.inArena and self:NeedsApply() then
            self.appliedThisArena = false
            self:Apply()
        end
    end, 1.5)
end

function PartyMark:OnEnable()
    self.announcedThisArena = false
    self.appliedThisArena = false
    self:EnsureOwnedClassIcons()
    self:RegisterMessage("AA_ARENA_JOINED", "OnArenaJoined")
    self:RegisterMessage("AA_ARENA_LEFT", "OnArenaLeft")
    self:RegisterEvent("GROUP_ROSTER_UPDATE", "OnRoster")
end

function PartyMark:OnDisable()
    self:CancelApplyTimers()
end

AA.PARTY_MARK_CLASS_ORDER = CLASS_ORDER
