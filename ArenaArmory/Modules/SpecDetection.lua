-- Spec inference from observed spells and buffs (no hostile inspect in TBC).
-- Enemies (arena1-5) drive the frame spec labels; friendly teammates are
-- tracked too so recorded matches carry specs for both teams.
local _, AA = ...
local addon = AA.addon

local SpecDetection = addon:NewModule("SpecDetection", "AceEvent-3.0")
AA.SpecDetection = SpecDetection

AA.detectedSpecs = {}  -- arena index -> spec name
AA.friendlySpecs = {}  -- teammate name (realm stripped) -> spec name

local FRIENDLY_UNITS = { "player", "party1", "party2", "party3", "party4" }

local function IsFriendlyArenaUnit(unit)
    return unit == "player" or (unit and unit:match("^party[1-4]$")) ~= nil
end

function SpecDetection:OnEnable()
    self:RegisterMessage("AA_CLEU", "OnCLEU")
    self:RegisterMessage("AA_ARENA_JOINED", "Reset")
    -- Buff scanning catches most specs at the gates (forms, talent auras,
    -- shields) before a single spell is cast.
    self:RegisterEvent("UNIT_AURA", "ScanBuffs")
    self:RegisterMessage("AA_OPPONENT_UPDATE", "OnOpponentUpdate")
end

function SpecDetection:OnOpponentUpdate(_, unit)
    self:ScanBuffs(nil, unit)
end

function SpecDetection:ScanBuffs(_, unit)
    if not AA.db.profile.specDetection.enabled then return end
    if IsFriendlyArenaUnit(unit) then
        self:ScanFriendlyBuffs(unit)
        return
    end
    local i = AA.ArenaIndex(unit)
    if not i or AA.detectedSpecs[i] then return end

    for index = 1, 40 do
        local name, _, _, _, _, _, source, spellId = AA.GetAuraByIndex(unit, index, "HELPFUL")
        if not name then break end
        local info = spellId and AA.SPEC_BUFFS[spellId]
        if info then
            -- Party-wide auras (Trueshot Aura, Earth Shield, Leader of the
            -- Pack) sit on teammates: attribute to the aura's caster when
            -- known, otherwise to the scanned unit - and only when the
            -- class matches, so a buffed teammate is never mislabeled.
            local target = (source and AA.ArenaIndex(source)) and source or unit
            local ti = AA.ArenaIndex(target)
            local _, classToken = UnitClass(target)
            classToken = classToken or AA.unitClass[target]
            if ti and not AA.detectedSpecs[ti] and classToken == info.class then
                self:SetSpec(ti, info.spec)
            end
        end
    end
end

function SpecDetection:ScanFriendlyBuffs(unit)
    if not AA.inArena or not UnitExists(unit) then return end
    for index = 1, 40 do
        local name, _, _, _, _, _, source, spellId = AA.GetAuraByIndex(unit, index, "HELPFUL")
        if not name then break end
        local info = spellId and AA.SPEC_BUFFS[spellId]
        if info then
            -- Same caster-attribution rule as the enemy path.
            local target = (source and IsFriendlyArenaUnit(source)) and source or unit
            local _, classToken = UnitClass(target)
            if classToken == info.class then
                self:SetFriendlySpec(AA.StripRealm(UnitName(target)), info.spec)
            end
        end
    end
end

function SpecDetection:SetFriendlySpec(name, spec)
    if not name or AA.friendlySpecs[name] then return end
    AA.friendlySpecs[name] = spec
    addon:SendMessage("AA_FRIENDLY_SPEC_DETECTED", name, spec)
end

function SpecDetection:Reset()
    wipe(AA.detectedSpecs)
    wipe(AA.friendlySpecs)
    for i = 1, AA.MAX_ARENA_OPPONENTS do
        local f = AA.GetFrame(i)
        if f then f.specText:SetText("") end
    end
    -- Catch talent auras/forms already up at the gates.
    for _, unit in ipairs(FRIENDLY_UNITS) do
        if UnitExists(unit) then self:ScanFriendlyBuffs(unit) end
    end
end

function SpecDetection:SetSpec(i, spec)
    if AA.detectedSpecs[i] then return end
    AA.detectedSpecs[i] = spec
    local f = AA.GetFrame(i)
    if f then f.specText:SetText(spec) end
    addon:SendMessage("AA_SPEC_DETECTED", i, spec)
end

function SpecDetection:OnCLEU(_, _, subevent, sourceGUID, sourceName, _, _, _, _, spellId)
    if not AA.db.profile.specDetection.enabled then return end
    if subevent ~= "SPELL_CAST_SUCCESS" and subevent ~= "SPELL_AURA_APPLIED"
        and subevent ~= "SPELL_CAST_START" then
        return
    end

    local info = spellId and AA.SPEC_SPELLS[spellId]
    if not info then return end

    local unit = AA.UnitByGUID(sourceGUID)
    if not unit then
        -- Friendly signature spell: attribute the spec to the teammate.
        for _, friendly in ipairs(FRIENDLY_UNITS) do
            if UnitExists(friendly) and UnitGUID(friendly) == sourceGUID then
                local _, classToken = UnitClass(friendly)
                if classToken == info.class then
                    self:SetFriendlySpec(AA.StripRealm(sourceName), info.spec)
                end
                return
            end
        end
        return
    end
    local i = AA.ArenaIndex(unit)
    if not i or AA.detectedSpecs[i] then return end

    -- Ignore mismatches (e.g. spell reflected or mirrored IDs).
    local classToken = AA.unitClass[unit]
    if classToken and classToken ~= info.class then return end

    self:SetSpec(i, info.spec)
end
