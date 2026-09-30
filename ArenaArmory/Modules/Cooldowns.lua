-- Enemy cooldown tracker: icons appear under each frame after first observed use.
local _, AA = ...
local addon = AA.addon

local Cooldowns = addon:NewModule("Cooldowns", "AceEvent-3.0")
AA.Cooldowns = Cooldowns

-- rows[i] = { icons = {}, byKey = {}, talented = {} }
--   byKey[key]    -> icon (all ranks / shared-cooldown spells map to one key)
--   talented[key] -> true once a recast proved the reduction talent
local rows = {}

-- Casts from enemies whose arenaN unit didn't exist yet (stealthed openers:
-- Cheap Shot -> Kidney, Sprint, Premeditation). Replayed once the GUID maps.
local pending = {}  -- guid -> { { spellId = n, start = t }, ... }
local PENDING_MAX_AGE = 60

-- Anchors the row either below the frame (tucked under the cast bar when one
-- is shown, directly under the bars otherwise) or to the right of the frame.
local function AnchorRow(i)
    local row = rows[i]
    local f = AA.GetFrame(i)
    if not row or not f then return end

    local cfg = AA.db.profile.cooldowns
    for slot, icon in ipairs(row.icons) do
        icon:SetSize(cfg.iconSize, cfg.iconSize)
        icon:ClearAllPoints()
        if slot == 1 then
            if cfg.position == "right" then
                local trinket = AA.GetTrinketIcon and AA.GetTrinketIcon(i)
                if trinket and AA.db.profile.trinket.enabled then
                    icon:SetPoint("TOPLEFT", trinket, "TOPRIGHT", 4, 0)
                else
                    icon:SetPoint("TOPLEFT", f, "TOPRIGHT", 4, 0)
                end
            elseif AA.db.profile.castbar.enabled then
                icon:SetPoint("TOPLEFT", f.castBar, "BOTTOMLEFT", -AA.db.profile.castbar.height, -2)
            else
                icon:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 0, -2)
            end
        else
            icon:SetPoint("LEFT", row.icons[slot - 1], "RIGHT", 2, 0)
        end
    end
end

local function CreateIcon(i, slot)
    local f = AA.GetFrame(i)
    local size = AA.db.profile.cooldowns.iconSize

    local icon = CreateFrame("Frame", nil, f)
    icon:SetSize(size, size)
    icon.texture = icon:CreateTexture(nil, "ARTWORK")
    icon.texture:SetAllPoints()
    icon.texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    icon.cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
    icon.cooldown:SetAllPoints()
    icon:Hide()
    return icon
end

function Cooldowns:OnFramesCreated()
    for i = 1, AA.MAX_ARENA_OPPONENTS do
        rows[i] = rows[i] or { icons = {}, byKey = {}, talented = {} }
    end
end

function Cooldowns:ApplyOptions()
    local cfg = AA.db.profile.cooldowns
    for i = 1, AA.MAX_ARENA_OPPONENTS do
        local row = rows[i]
        if row then
            AnchorRow(i)
            if cfg.enabled then
                -- Restore icons for anything still being tracked.
                for _, icon in pairs(row.byKey) do icon:Show() end
            else
                for _, icon in ipairs(row.icons) do icon:Hide() end
            end
        end
    end
end

function Cooldowns:OnEnable()
    self:RegisterMessage("AA_FRAMES_CREATED", "OnFramesCreated")
    self:RegisterMessage("AA_CLEU", "OnCLEU")
    self:RegisterMessage("AA_ARENA_JOINED", "Reset")
    self:RegisterMessage("AA_OPPONENT_UPDATE", "OnOpponentUpdate")
    self:RegisterMessage("AA_SPEC_DETECTED", "OnSpecDetected")
    self:OnFramesCreated()
end

function Cooldowns:Reset()
    wipe(pending)
    for i = 1, AA.MAX_ARENA_OPPONENTS do
        local row = rows[i]
        if row then
            wipe(row.byKey)
            wipe(row.talented)
            for _, icon in ipairs(row.icons) do
                icon:Hide()
                icon.cooldown:Clear()
                icon.def, icon.start, icon.duration = nil, nil, nil
            end
        end
    end
end

local function DurationFor(i, def)
    local row = rows[i]
    if def.talentCd and row and row.talented[def.key] then return def.talentCd end
    return AA.CooldownFor(def, AA.detectedSpecs[i])
end

local function AcquireIcon(i, key, textureSpell)
    local row = rows[i]
    local icon = row.byKey[key]
    if icon then return icon end

    local slot = 0
    for s = 1, AA.db.profile.cooldowns.maxIcons do
        if not row.icons[s] then
            row.icons[s] = CreateIcon(i, s)
            AnchorRow(i)
        end
        local used = false
        for _, existing in pairs(row.byKey) do
            if existing == row.icons[s] then used = true break end
        end
        if not used then slot = s break end
    end
    if slot == 0 then return nil end
    icon = row.icons[slot]
    row.byKey[key] = icon
    local tex = AA.GetSpellTexture(textureSpell)
    icon.texture:SetTexture(tex or "Interface\\Icons\\INV_Misc_QuestionMark")
    return icon
end

-- Readiness / Preparation / Cold Snap: finish the listed cooldowns.
local function ApplyResets(i, def)
    local row = rows[i]
    local classWide = type(def.resets) == "string" and def.resets
    local keys = {}
    if not classWide then
        for _, k in ipairs(def.resets) do keys[k] = true end
    end
    for key, icon in pairs(row.byKey) do
        local d = icon.def
        if d and key ~= def.key and (keys[key] or (classWide and d.class == classWide)) then
            icon.cooldown:Clear()
            icon.start, icon.duration = nil, nil
        end
    end
end

-- `cdOverride` is for callers without a def (test mode's trinket preview);
-- `start` backdates replayed casts from before the enemy's unit existed.
function Cooldowns:Track(i, spellId, cdOverride, start)
    local row = rows[i]
    if not row then return end
    local def = AA.COOLDOWN_SPELLS[spellId]
    local key = def and def.key or spellId
    local now = GetTime()
    start = start or now

    local icon = AcquireIcon(i, key, def and def.icon or spellId)
    if not icon then return end

    if def then
        -- A recast before the assumed cooldown elapsed proves the talent.
        if def.talentCd and not row.talented[key] and icon.start and icon.duration
            and icon.duration > def.talentCd then
            local elapsed = start - icon.start
            if elapsed < icon.duration - 1 and elapsed >= def.talentCd - 1 then
                row.talented[key] = true
            end
        end
        if def.resets then ApplyResets(i, def) end
    end

    local duration = cdOverride or DurationFor(i, def)
    icon.def, icon.start, icon.duration = def, start, duration
    icon.cooldown:SetCooldown(start, duration)
    icon:Show()
end

-- Spec just became known: re-time running cooldowns whose talent depends on it.
function Cooldowns:OnSpecDetected(_, i)
    local row = rows[i]
    if not row then return end
    local now = GetTime()
    for _, icon in pairs(row.byKey) do
        local def = icon.def
        if def and def.talentCd and icon.start then
            local duration = DurationFor(i, def)
            if duration ~= icon.duration then
                icon.duration = duration
                if icon.start + duration > now then
                    icon.cooldown:SetCooldown(icon.start, duration)
                else
                    icon.cooldown:Clear()
                end
            end
        end
    end
end

function Cooldowns:OnOpponentUpdate(_, unit)
    local guid = unit and UnitGUID(unit)
    local list = guid and pending[guid]
    if not list then return end
    pending[guid] = nil
    local i = AA.ArenaIndex(unit)
    if not i or not AA.db.profile.cooldowns.enabled then return end
    local now = GetTime()
    for _, cast in ipairs(list) do
        if now - cast.start < PENDING_MAX_AGE then
            self:Track(i, cast.spellId, nil, cast.start)
        end
    end
end

function Cooldowns:OnCLEU(_, _, subevent, sourceGUID, _, sourceFlags, _, _, _, spellId)
    if not AA.db.profile.cooldowns.enabled then return end
    if subevent ~= "SPELL_CAST_SUCCESS" then return end
    if not AA.COOLDOWN_SPELLS[spellId] then return end

    local unit = AA.UnitByGUIDOrPet(sourceGUID)
    if not unit then
        if AA.inArena and sourceGUID and AA.IsHostilePlayerFlag(sourceFlags) then
            local list = pending[sourceGUID] or {}
            pending[sourceGUID] = list
            list[#list + 1] = { spellId = spellId, start = GetTime() }
        end
        return
    end
    local i = AA.ArenaIndex(unit)
    if not i then return end

    self:Track(i, spellId)
end
