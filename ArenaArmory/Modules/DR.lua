-- Diminishing returns tracker per arena opponent, driven by DRList-1.0.
local _, AA = ...
local addon = AA.addon

local DR = addon:NewModule("DR", "AceEvent-3.0", "AceTimer-3.0")
AA.DR = DR

local DRList = LibStub("DRList-1.0")

local MAX_DR_ICONS = 6
local DR_TEXT = { "\194\189", "\194\188", "0" } -- 1/2, 1/4, immune
local DR_COLOR = { {0, 1, 0}, {1, 0.85, 0}, {1, 0, 0} }

local rows = {}   -- rows[i] = { icons... }
local state = {}  -- state[i][category] = { level, expires, active, spellId }

-- Anchors a row to the left of the class icon (default) or to the right of
-- the trinket icon, growing outward.
local function AnchorRow(i)
    local f = AA.GetFrame(i)
    local row = rows[i]
    if not f or not row then return end

    local size = AA.db.profile.dr.iconSize
    local onLeft = AA.db.profile.dr.position == "left"
    local trinket = AA.GetTrinketIcon and AA.GetTrinketIcon(i)

    for n, icon in ipairs(row) do
        icon:SetSize(size, size)
        icon:ClearAllPoints()
        if onLeft then
            if n == 1 then
                icon:SetPoint("TOPRIGHT", f, "TOPLEFT", -4, 0)
            else
                icon:SetPoint("RIGHT", row[n - 1], "LEFT", -2, 0)
            end
        else
            if n == 1 then
                if trinket and AA.db.profile.trinket.enabled then
                    icon:SetPoint("TOPLEFT", trinket, "TOPRIGHT", 4, 0)
                else
                    icon:SetPoint("TOPLEFT", f, "TOPRIGHT", 4, 0)
                end
            else
                icon:SetPoint("LEFT", row[n - 1], "RIGHT", 2, 0)
            end
        end
    end
end

local function CreateRow(i)
    local f = AA.GetFrame(i)
    local size = AA.db.profile.dr.iconSize

    local row = {}
    for n = 1, MAX_DR_ICONS do
        local icon = CreateFrame("Frame", nil, f)
        icon:SetSize(size, size)
        icon.texture = icon:CreateTexture(nil, "ARTWORK")
        icon.texture:SetAllPoints()
        icon.texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        icon.cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
        icon.cooldown:SetAllPoints()
        icon.cooldown:SetReverse(true)
        icon.border = icon:CreateTexture(nil, "OVERLAY")
        icon.border:SetPoint("TOPLEFT", -1, 1)
        icon.border:SetPoint("BOTTOMRIGHT", 1, -1)
        icon.border:SetColorTexture(0, 1, 0, 0)
        icon.text = icon:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        icon.text:SetPoint("BOTTOMRIGHT", 2, -2)
        icon:Hide()
        row[n] = icon
    end
    return row
end

function DR:OnFramesCreated()
    for i = 1, AA.MAX_ARENA_OPPONENTS do
        rows[i] = rows[i] or CreateRow(i)
        state[i] = state[i] or {}
        AnchorRow(i)
    end
end

function DR:ApplyOptions()
    for i = 1, AA.MAX_ARENA_OPPONENTS do
        AnchorRow(i)
        self:UpdateIcons(i)
    end
end

function DR:OnEnable()
    self:RegisterMessage("AA_FRAMES_CREATED", "OnFramesCreated")
    self:RegisterMessage("AA_CLEU", "OnCLEU")
    self:RegisterMessage("AA_ARENA_JOINED", "Reset")
    self:ScheduleRepeatingTimer("Prune", 0.5)
    if AA.frames and AA.frames[1] then
        self:OnFramesCreated()
    end
end

function DR:Reset()
    for i = 1, AA.MAX_ARENA_OPPONENTS do
        if state[i] then wipe(state[i]) end
        self:UpdateIcons(i)
    end
end

function DR:Handle(i, category, spellId, faded)
    local st = state[i][category]
    if not st then
        st = { level = 0, expires = 0, active = false }
        state[i][category] = st
    end

    if not faded then
        -- New application: if the reset window elapsed, DR starts fresh.
        if not st.active and st.expires > 0 and GetTime() > st.expires then
            st.level = 0
        end
        st.level = math.min(st.level + 1, 3)
        st.spellId = spellId
        st.active = true
        st.expires = 0
    else
        -- Aura faded: reset window starts now.
        st.active = false
        st.expires = GetTime() + (DRList:GetResetTime(category) or 18)
    end
    self:UpdateIcons(i)
end

function DR:Prune()
    if not AA.db.profile.dr.enabled then return end
    local now = GetTime()
    for i = 1, AA.MAX_ARENA_OPPONENTS do
        local dirty = false
        if state[i] then
            for category, st in pairs(state[i]) do
                if not st.active and st.expires > 0 and now > st.expires then
                    state[i][category] = nil
                    dirty = true
                end
            end
        end
        if dirty then self:UpdateIcons(i) end
    end
end

function DR:UpdateIcons(i)
    local row = rows[i]
    if not row then return end

    local n = 0
    if state[i] and AA.db.profile.dr.enabled then
        for _, st in pairs(state[i]) do
            n = n + 1
            if n > MAX_DR_ICONS then break end
            local icon = row[n]
            local tex = st.spellId and AA.GetSpellTexture(st.spellId)
            icon.texture:SetTexture(tex or "Interface\\Icons\\INV_Misc_QuestionMark")
            local lvl = math.min(st.level, 3)
            icon.text:SetText(DR_TEXT[lvl] or "")
            local c = DR_COLOR[lvl]
            if c then icon.text:SetTextColor(c[1], c[2], c[3]) end
            if not st.active and st.expires > 0 then
                local reset = DRList:GetResetTime() or 18
                icon.cooldown:SetCooldown(st.expires - reset, reset)
            else
                icon.cooldown:Clear()
            end
            icon:Show()
        end
    end
    for k = n + 1, MAX_DR_ICONS do
        row[k]:Hide()
    end
end

function DR:OnCLEU(_, _, subevent, _, _, _, destGUID, _, _, spellId, _, _, auraType)
    if not AA.db.profile.dr.enabled then return end
    if auraType ~= "DEBUFF" then return end

    local unit = AA.UnitByGUID(destGUID)
    if not unit then return end
    local i = AA.ArenaIndex(unit)
    if not i then return end

    local category = DRList:GetCategoryBySpellID(spellId)
    if not category or category == "knockback" then return end

    if subevent == "SPELL_AURA_APPLIED" or subevent == "SPELL_AURA_REFRESH" then
        self:Handle(i, category, spellId, false)
    elseif subevent == "SPELL_AURA_REMOVED" then
        self:Handle(i, category, spellId, true)
    end
end
