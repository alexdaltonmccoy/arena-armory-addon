-- Enemy spec inference from observed spells (no hostile inspect in TBC).
local _, AA = ...
local addon = AA.addon

local SpecDetection = addon:NewModule("SpecDetection", "AceEvent-3.0")
AA.SpecDetection = SpecDetection

AA.detectedSpecs = {}  -- arena index -> spec name

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

function SpecDetection:Reset()
    wipe(AA.detectedSpecs)
    for i = 1, AA.MAX_ARENA_OPPONENTS do
        local f = AA.GetFrame(i)
        if f then f.specText:SetText("") end
    end
end

function SpecDetection:SetSpec(i, spec)
    if AA.detectedSpecs[i] then return end
    AA.detectedSpecs[i] = spec
    local f = AA.GetFrame(i)
    if f then f.specText:SetText(spec) end
    addon:SendMessage("AA_SPEC_DETECTED", i, spec)
end

function SpecDetection:OnCLEU(_, _, subevent, sourceGUID, _, _, _, _, _, spellId)
    if not AA.db.profile.specDetection.enabled then return end
    if subevent ~= "SPELL_CAST_SUCCESS" and subevent ~= "SPELL_AURA_APPLIED"
        and subevent ~= "SPELL_CAST_START" then
        return
    end

    local info = spellId and AA.SPEC_SPELLS[spellId]
    if not info then return end
    local unit = AA.UnitByGUID(sourceGUID)
    if not unit then return end
    local i = AA.ArenaIndex(unit)
    if not i or AA.detectedSpecs[i] then return end

    -- Ignore mismatches (e.g. spell reflected or mirrored IDs).
    local classToken = AA.unitClass[unit]
    if classToken and classToken ~= info.class then return end

    self:SetSpec(i, info.spec)
end
