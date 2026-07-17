-- PvP trinket + racial CC break (Will of the Forsaken) tracker per opponent.
-- In TBC these do NOT share a cooldown, so each gets its own icon: the
-- medallion sits right of the frame, the racial right of the medallion
-- (hidden until first used).
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
local racials = {}

local function CreateCooldownIcon(parent, size)
    local icon = CreateFrame("Frame", nil, parent)
    icon:SetSize(size, size)
    icon.texture = icon:CreateTexture(nil, "ARTWORK")
    icon.texture:SetAllPoints()
    icon.texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    icon.cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
    icon.cooldown:SetAllPoints()
    return icon
end

local function CreateTrinketIcon(i)
    local f = AA.GetFrame(i)
    local size = AA.db.profile.trinket.size

    local icon = CreateCooldownIcon(f, size)
    icon:SetPoint("TOPLEFT", f, "TOPRIGHT", 4, 0)
    icon.texture:SetTexture(TrinketIconFor(i))
    icon:SetShown(AA.db.profile.trinket.enabled)
    return icon
end

local function CreateRacialIcon(i)
    local f = AA.GetFrame(i)
    local size = AA.db.profile.trinket.size

    local icon = CreateCooldownIcon(f, size)
    icon:SetPoint("TOPLEFT", icons[i], "TOPRIGHT", 4, 0)
    icon:Hide() -- revealed on first use; the enemy's racial isn't known before
    return icon
end

function Trinket:OnFramesCreated()
    for i = 1, AA.MAX_ARENA_OPPONENTS do
        icons[i] = icons[i] or CreateTrinketIcon(i)
        racials[i] = racials[i] or CreateRacialIcon(i)
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
        local racial = racials[i]
        if racial then
            racial:SetSize(cfg.size, cfg.size)
            if not cfg.trackRacial then racial:Hide() end
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
        if racials[i] then
            racials[i].cooldown:Clear()
            racials[i].lastUse = nil
            racials[i]:Hide()
        end
    end
end

function Trinket:StartCooldown(i, spellId, cd)
    -- Trinket and racial CC breaks don't share a cooldown in TBC: each gets
    -- its own icon so both states are visible at once.
    local isRacial = not AA.TRINKET_SPELLS[spellId]
    local icon = isRacial and racials[i] or icons[i]
    if not icon then return end
    if isRacial and not AA.db.profile.trinket.trackRacial then return end

    -- Both CLEU and UNIT_SPELLCAST_SUCCEEDED can report the same use.
    local now = GetTime()
    if icon.lastUse and (now - icon.lastUse) < 2 then return end
    icon.lastUse = now

    if isRacial then
        local tex = AA.GetSpellTexture(spellId)
        if tex then icon.texture:SetTexture(tex) end
        icon:Show()
    else
        icon.texture:SetTexture(TrinketIconFor(i))
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

    local cd = AA.TRINKET_SPELLS[spellId] or AA.RACIAL_CC_BREAKS[spellId]
    if cd then
        self:StartCooldown(i, spellId, cd)
    end
end

function AA.GetTrinketIcon(i)
    return icons[i]
end
