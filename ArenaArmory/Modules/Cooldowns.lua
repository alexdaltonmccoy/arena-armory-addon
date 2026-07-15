-- Enemy cooldown tracker: icons appear under each frame after first observed use.
local _, AA = ...
local addon = AA.addon

local Cooldowns = addon:NewModule("Cooldowns", "AceEvent-3.0")
AA.Cooldowns = Cooldowns

local rows = {}  -- rows[i] = { icons = {}, bySpell = {} }

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
        rows[i] = rows[i] or { icons = {}, bySpell = {} }
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
                for _, icon in pairs(row.bySpell) do icon:Show() end
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
    self:OnFramesCreated()
end

function Cooldowns:Reset()
    for i = 1, AA.MAX_ARENA_OPPONENTS do
        local row = rows[i]
        if row then
            wipe(row.bySpell)
            for _, icon in ipairs(row.icons) do
                icon:Hide()
                icon.cooldown:Clear()
            end
        end
    end
end

function Cooldowns:Track(i, spellId, cd)
    local row = rows[i]
    if not row then return end

    local icon = row.bySpell[spellId]
    if not icon then
        local slot = 0
        for s = 1, AA.db.profile.cooldowns.maxIcons do
            if not row.icons[s] then
                row.icons[s] = CreateIcon(i, s)
                AnchorRow(i)
            end
            local used = false
            for _, existing in pairs(row.bySpell) do
                if existing == row.icons[s] then used = true break end
            end
            if not used then slot = s break end
        end
        if slot == 0 then return end
        icon = row.icons[slot]
        row.bySpell[spellId] = icon
        local tex = AA.GetSpellTexture(spellId)
        icon.texture:SetTexture(tex or "Interface\\Icons\\INV_Misc_QuestionMark")
    end

    icon.cooldown:SetCooldown(GetTime(), cd)
    icon:Show()
end

function Cooldowns:OnCLEU(_, _, subevent, sourceGUID, _, _, _, _, _, spellId)
    if not AA.db.profile.cooldowns.enabled then return end
    if subevent ~= "SPELL_CAST_SUCCESS" then return end

    local info = AA.COOLDOWN_SPELLS[spellId]
    if not info then return end
    local unit = AA.UnitByGUID(sourceGUID)
    if not unit then return end
    local i = AA.ArenaIndex(unit)
    if not i then return end

    self:Track(i, spellId, info.cd)
end
