-- PvP trinket / Will of the Forsaken usage tracker per arena opponent.
local _, AA = ...
local addon = AA.addon

local Trinket = addon:NewModule("Trinket", "AceEvent-3.0")
AA.Trinket = Trinket

-- The PvP trinket SPELL (42292) uses the dispel-magic art, so we always show
-- the medallion ITEM art for the opponent's faction instead.
local TRINKET_ICONS = {
    Alliance = "Interface\\Icons\\INV_Jewelry_TrinketPVP_01",
    Horde = "Interface\\Icons\\INV_Jewelry_TrinketPVP_02",
}

local function TrinketIconFor(i)
    local faction = UnitFactionGroup("arena" .. i)
    if not faction then
        -- Unknown enemy: assume the opposite of the player's faction.
        faction = UnitFactionGroup("player") == "Alliance" and "Horde" or "Alliance"
    end
    return TRINKET_ICONS[faction] or TRINKET_ICONS.Horde
end

local icons = {}

local function CreateTrinketIcon(i)
    local f = AA.GetFrame(i)
    local size = AA.db.profile.trinket.size

    local icon = CreateFrame("Frame", nil, f)
    icon:SetSize(size, size)
    icon:SetPoint("TOPLEFT", f, "TOPRIGHT", 4, 0)
    icon.texture = icon:CreateTexture(nil, "ARTWORK")
    icon.texture:SetAllPoints()
    icon.texture:SetTexture(TrinketIconFor(i))
    icon.texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    icon.cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
    icon.cooldown:SetAllPoints()
    icon:SetShown(AA.db.profile.trinket.enabled)
    return icon
end

function Trinket:OnFramesCreated()
    for i = 1, AA.MAX_ARENA_OPPONENTS do
        icons[i] = icons[i] or CreateTrinketIcon(i)
    end
end

function Trinket:ApplyOptions()
    local cfg = AA.db.profile.trinket
    for i = 1, AA.MAX_ARENA_OPPONENTS do
        local icon = icons[i]
        if icon then
            icon:SetSize(cfg.size, cfg.size)
            icon:SetShown(cfg.enabled)
        end
    end
end

function Trinket:OnEnable()
    self:RegisterMessage("AA_FRAMES_CREATED", "OnFramesCreated")
    self:RegisterMessage("AA_CLEU", "OnCLEU")
    self:RegisterMessage("AA_ARENA_JOINED", "Reset")
    -- Primary detection: unit event straight off the arena unit token (what
    -- Gladdy uses) - it needs no GUID mapping and can't miss due to map lag.
    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", "OnUnitSpellcast")
    if AA.frames and AA.frames[1] then
        self:OnFramesCreated()
    end
end

function Trinket:OnUnitSpellcast(_, unit, _, spellId)
    if not AA.db.profile.trinket.enabled then return end
    local i = AA.ArenaIndex(unit)
    if not i then return end

    local cd = AA.TRINKET_SPELLS[spellId] or AA.RACIAL_CC_BREAKS[spellId]
    if cd then
        self:StartCooldown(i, spellId, cd)
    end
end

function Trinket:Reset()
    for i = 1, AA.MAX_ARENA_OPPONENTS do
        if icons[i] then
            icons[i].cooldown:Clear()
            icons[i].texture:SetTexture(TrinketIconFor(i))
            icons[i].lastUse = nil
        end
    end
end

function Trinket:StartCooldown(i, spellId, cd)
    local icon = icons[i]
    if not icon then return end
    -- Both CLEU and UNIT_SPELLCAST_SUCCEEDED can report the same use.
    local now = GetTime()
    if icon.lastUse and (now - icon.lastUse) < 2 then return end
    icon.lastUse = now

    if AA.TRINKET_SPELLS[spellId] then
        icon.texture:SetTexture(TrinketIconFor(i))
    else
        -- Racial CC break (e.g. Will of the Forsaken): show that spell's art.
        local tex = AA.GetSpellTexture(spellId)
        if tex then icon.texture:SetTexture(tex) end
    end
    icon.cooldown:SetCooldown(now, cd)
    addon:SendMessage("AA_TRINKET_USED", i, spellId)
end

function Trinket:OnCLEU(_, _, subevent, sourceGUID, _, _, _, _, _, spellId)
    if not AA.db.profile.trinket.enabled then return end
    if subevent ~= "SPELL_CAST_SUCCESS" then return end
    local unit = AA.UnitByGUID(sourceGUID)
    if not unit then return end
    local i = AA.ArenaIndex(unit)
    if not i then return end

    local cd = AA.TRINKET_SPELLS[spellId]
    if cd then
        self:StartCooldown(i, spellId, cd)
        return
    end
    local racialCd = AA.RACIAL_CC_BREAKS[spellId]
    if racialCd then
        self:StartCooldown(i, spellId, racialCd)
    end
end

function AA.GetTrinketIcon(i)
    return icons[i]
end
