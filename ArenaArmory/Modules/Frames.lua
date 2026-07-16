-- Arena enemy frames: anchor, health/power bars, class icon, name, cast bar.
--
-- Structure: each frame is an INSECURE visual frame (so it can be shown,
-- hidden, and updated freely in combat) with a secure click-overlay child
-- (SecureUnitButtonTemplate) for target/focus clicks. Frames appear when an
-- opponent is first seen and then PERSIST through stealth (dimmed), death,
-- and leaving - they only clear when the match ends.
local _, AA = ...
local addon = AA.addon

local Frames = addon:NewModule("Frames", "AceEvent-3.0", "AceTimer-3.0")
AA.Frames = Frames

local CLASS_ICONS = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes"
local FLAT_TEXTURE = "Interface\\Buttons\\WHITE8X8"
local CLASSIC_TEXTURE = "Interface\\TargetingFrame\\UI-StatusBar"

local STEALTH_ALPHA = 0.6

local anchor
local frames = {}
AA.frames = frames

local function BarTexture()
    return AA.db.profile.frames.style == "classic" and CLASSIC_TEXTURE or FLAT_TEXTURE
end

-------------------------------------------------------------------------------
-- Anchor
-------------------------------------------------------------------------------

local function SavePosition()
    local point, _, relativePoint, x, y = anchor:GetPoint()
    local pos = AA.db.profile.position
    pos.point, pos.relativePoint, pos.x, pos.y = point, relativePoint, x, y
end

-- Idempotent stop: OnDragStop is not always delivered (mouse released over
-- another frame, lock toggled mid-drag, frame hidden), which left the anchor
-- glued to the cursor. Every stop path funnels through here.
local function StopMovingAnchor()
    if not anchor or not anchor.isMoving then return end
    anchor.isMoving = false
    anchor:StopMovingOrSizing()
    SavePosition()
end

local function CreateAnchor()
    anchor = CreateFrame("Frame", "ArenaArmoryAnchor", UIParent)
    anchor:SetSize(220, 20)
    anchor:SetMovable(true)
    anchor:SetClampedToScreen(true)
    anchor:EnableMouse(true)
    anchor:RegisterForDrag("LeftButton")
    anchor:SetScript("OnDragStart", function(self)
        if not AA.db.profile.locked then
            self.isMoving = true
            self:StartMoving()
        end
    end)
    anchor:SetScript("OnDragStop", StopMovingAnchor)
    anchor:SetScript("OnMouseUp", StopMovingAnchor)
    anchor:SetScript("OnHide", StopMovingAnchor)

    anchor.bg = anchor:CreateTexture(nil, "BACKGROUND")
    anchor.bg:SetAllPoints()
    anchor.bg:SetColorTexture(0.1, 0.6, 0.3, 0.6)

    anchor.label = anchor:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    anchor.label:SetPoint("CENTER")
    anchor.label:SetText("Arena Armory - drag to move (/aa lock)")

    local pos = AA.db.profile.position
    anchor:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
end

-------------------------------------------------------------------------------
-- Styling (Modern = flat Midnight-like, Classic = traditional WoW gloss)
-------------------------------------------------------------------------------

-- Outline + drop shadow in every style: bar colors range from white (priest)
-- to dark blue (shaman), so unoutlined text is unreadable on half the classes.
local function StyleFont(fontString, size)
    local font = fontString:GetFont()
    if font then
        fontString:SetFont(font, size, "OUTLINE")
        fontString:SetShadowColor(0, 0, 0, 0.9)
        fontString:SetShadowOffset(1, -1)
    end
end

local function ApplyGradient(tex)
    -- Subtle top-lit sheen on the flat texture; API differs across builds.
    if tex.SetGradient and CreateColor then
        tex:SetGradient("VERTICAL",
            CreateColor(0, 0, 0, 0.18),
            CreateColor(1, 1, 1, 0.12))
    end
end

function Frames:ApplyStyle(f)
    local modern = AA.db.profile.frames.style ~= "classic"
    local barTex = BarTexture()

    f.healthBar:SetStatusBarTexture(barTex)
    f.powerBar:SetStatusBarTexture(barTex)
    f.castBar:SetStatusBarTexture(barTex)
    f.healthBar.bg:SetTexture(barTex)
    f.powerBar.bg:SetTexture(barTex)
    f.castBar.bg:SetTexture(barTex)

    if modern then
        f.border:Show()
        f.healthBar.bg:SetVertexColor(0.07, 0.07, 0.09, 0.9)
        f.powerBar.bg:SetVertexColor(0.07, 0.07, 0.09, 0.9)
        f.castBar.bg:SetVertexColor(0.07, 0.07, 0.09, 0.9)
        f.healthBar.sheen:Show()
        ApplyGradient(f.healthBar.sheen)
    else
        f.border:Hide()
        f.healthBar.bg:SetVertexColor(0.15, 0.15, 0.15, 0.9)
        f.powerBar.bg:SetVertexColor(0.15, 0.15, 0.15, 0.9)
        f.castBar.bg:SetVertexColor(0.15, 0.15, 0.15, 0.9)
        f.healthBar.sheen:Hide()
    end

    local fontSize = AA.db.profile.frames.fontSize or 11
    StyleFont(f.nameText, fontSize + 1)
    StyleFont(f.healthText, fontSize)
    StyleFont(f.specText, fontSize - 1)
    StyleFont(f.powerText, fontSize - 1)
    StyleFont(f.castBar.text, fontSize - 1)

    self:ApplyTextLayout(f)

    -- Re-assert bar color for the new texture.
    if f.classToken then
        self:SetFrameClass(f, f.classToken)
    end
end

-- Anchors the spec/health/power texts per config: spec either sits on the
-- power bar directly below the name (Gladdy-style) or on the health bar's
-- right; the health text centers vertically when it has the right side alone.
function Frames:ApplyTextLayout(f)
    local cfg = AA.db.profile.frames
    local onPower = cfg.specPosition ~= "health" and cfg.showPowerBar
    f.specText:ClearAllPoints()
    f.healthText:ClearAllPoints()
    if onPower then
        f.specText:SetPoint("LEFT", f.powerBar, "LEFT", 4, 0)
        f.specText:SetJustifyH("LEFT")
        f.healthText:SetPoint("RIGHT", f.healthBar, "RIGHT", -4, 0)
    else
        f.specText:SetPoint("RIGHT", f.healthBar, "RIGHT", -4, 6)
        f.specText:SetJustifyH("RIGHT")
        f.healthText:SetPoint("RIGHT", f.healthBar, "RIGHT", -4, -6)
    end
end

function Frames:ApplyStyles()
    for i = 1, AA.MAX_ARENA_OPPONENTS do
        if frames[i] then self:ApplyStyle(frames[i]) end
    end
end

-------------------------------------------------------------------------------
-- Unit frame construction
-------------------------------------------------------------------------------

local function CreateUnitFrame(i)
    local cfg = AA.db.profile.frames
    local unit = "arena" .. i

    local f = CreateFrame("Frame", "ArenaArmoryFrame" .. i, UIParent)
    f.unit = unit
    f.index = i
    f.seen = false
    f:SetSize(cfg.width + cfg.height, cfg.height)

    -- 1px border behind everything (modern style only)
    f.border = f:CreateTexture(nil, "BACKGROUND", nil, -8)
    f.border:SetPoint("TOPLEFT", -1, 1)
    f.border:SetPoint("BOTTOMRIGHT", 1, -1)
    f.border:SetColorTexture(0, 0, 0, 0.9)

    -- Class icon (left, square)
    f.classIcon = f:CreateTexture(nil, "ARTWORK")
    f.classIcon:SetSize(cfg.height, cfg.height)
    f.classIcon:SetPoint("TOPLEFT", 0, 0)
    f.classIcon:SetTexture(CLASS_ICONS)

    -- CC/aura overlay on the class icon
    f.auraOverlay = CreateFrame("Frame", nil, f)
    f.auraOverlay:SetAllPoints(f.classIcon)
    f.auraOverlay:SetFrameLevel(f:GetFrameLevel() + 5)
    f.auraOverlay.icon = f.auraOverlay:CreateTexture(nil, "ARTWORK")
    f.auraOverlay.icon:SetAllPoints()
    f.auraOverlay.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    f.auraOverlay.cooldown = CreateFrame("Cooldown", nil, f.auraOverlay, "CooldownFrameTemplate")
    f.auraOverlay.cooldown:SetAllPoints()
    f.auraOverlay.cooldown:SetReverse(true)
    f.auraOverlay:Hide()

    -- Health bar
    local powerH = cfg.showPowerBar and cfg.powerBarHeight or 0
    f.healthBar = CreateFrame("StatusBar", nil, f)
    f.healthBar:SetPoint("TOPLEFT", f.classIcon, "TOPRIGHT", 1, 0)
    f.healthBar:SetSize(cfg.width, cfg.height - powerH - 1)
    f.healthBar:SetMinMaxValues(0, 1)
    f.healthBar.bg = f.healthBar:CreateTexture(nil, "BACKGROUND")
    f.healthBar.bg:SetAllPoints()
    f.healthBar.sheen = f.healthBar:CreateTexture(nil, "OVERLAY")
    f.healthBar.sheen:SetAllPoints()
    f.healthBar.sheen:SetTexture(FLAT_TEXTURE)

    f.nameText = f.healthBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.nameText:SetPoint("LEFT", f.healthBar, "LEFT", 4, 0)
    f.nameText:SetJustifyH("LEFT")

    f.specText = f.healthBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.specText:SetPoint("RIGHT", f.healthBar, "RIGHT", -4, 6)
    f.specText:SetJustifyH("RIGHT")

    f.healthText = f.healthBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.healthText:SetPoint("RIGHT", f.healthBar, "RIGHT", -4, -6)

    -- Power bar
    f.powerBar = CreateFrame("StatusBar", nil, f)
    f.powerBar:SetPoint("TOPLEFT", f.healthBar, "BOTTOMLEFT", 0, -1)
    f.powerBar:SetSize(cfg.width, math.max(powerH - 1, 1))
    f.powerBar:SetMinMaxValues(0, 1)
    f.powerBar.bg = f.powerBar:CreateTexture(nil, "BACKGROUND")
    f.powerBar.bg:SetAllPoints()

    f.powerText = f.powerBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.powerText:SetPoint("RIGHT", f.powerBar, "RIGHT", -4, 0)
    f.powerText:SetJustifyH("RIGHT")

    if not cfg.showPowerBar then f.powerBar:Hide() end

    -- Cast bar (below the frame body)
    f.castBar = CreateFrame("StatusBar", nil, f)
    f.castBar:SetStatusBarColor(1, 0.7, 0)
    f.castBar:SetPoint("TOPLEFT", f.powerBar, "BOTTOMLEFT", 0, -2)
    f.castBar:SetSize(cfg.width - AA.db.profile.castbar.height, AA.db.profile.castbar.height)
    f.castBar:SetMinMaxValues(0, 1)
    f.castBar.bg = f.castBar:CreateTexture(nil, "BACKGROUND")
    f.castBar.bg:SetAllPoints()
    f.castBar.icon = f.castBar:CreateTexture(nil, "ARTWORK")
    f.castBar.icon:SetSize(AA.db.profile.castbar.height, AA.db.profile.castbar.height)
    f.castBar.icon:SetPoint("RIGHT", f.castBar, "LEFT", 0, 0)
    f.castBar.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    f.castBar.text = f.castBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.castBar.text:SetPoint("LEFT", 4, 0)
    f.castBar:Hide()

    f.castBar:SetScript("OnUpdate", function(bar)
        if not bar.endTime then return end
        local now = GetTime()
        local remaining = bar.endTime - now
        if remaining <= 0 then
            bar:Hide()
            bar.endTime = nil
            return
        end
        local total = bar.endTime - bar.startTime
        local progress = (now - bar.startTime) / total
        bar:SetValue(bar.channeling and (1 - progress) or progress)
    end)

    -- Secure click overlay: attributes are set once at load (out of combat)
    -- and never touched again, so hiding/showing the insecure parent in
    -- combat is legal and clicks always target the right unit.
    f.secure = CreateFrame("Button", "ArenaArmorySecure" .. i, f, "SecureUnitButtonTemplate")
    f.secure:SetAllPoints(f)
    f.secure:SetFrameLevel(f:GetFrameLevel() + 10)
    f.secure:SetAttribute("unit", unit)
    f.secure:SetAttribute("type1", "target")
    f.secure:SetAttribute("type2", "focus")
    f.secure:RegisterForClicks("AnyUp")

    -- Shift-left-click pops the arenaarmory.com lookup for this opponent.
    -- Insecure post-hook: doesn't interfere with the secure targeting action.
    f.secure:HookScript("OnClick", function(_, button)
        if button == "LeftButton" and IsShiftKeyDown() and AA.LookupUnit then
            AA.LookupUnit(unit)
        end
    end)

    Frames:ApplyStyle(f)
    f:Hide()
    return f
end

-- Neutral look for a frame whose opponent hasn't been identified yet
-- (e.g. a rogue who is still stealthed).
local function ApplyPlaceholder(f)
    f.classToken = nil
    f.classIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    f.classIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    f.nameText:SetText("Enemy " .. f.index)
    f.specText:SetText(AA.detectedSpecs and AA.detectedSpecs[f.index] or "")
    f.healthText:SetText("")
    f.powerText:SetText("")
    f.healthBar:SetStatusBarColor(0.4, 0.4, 0.4)
    f.healthBar:SetValue(1)
    f.powerBar:SetValue(0)
end

local function ClearFrame(f)
    f.seen = false
    f.guid = nil
    f.prefilled = nil
    f.classToken = nil
    f.nameText:SetText("")
    f.specText:SetText("")
    f.healthText:SetText("")
    f.powerText:SetText("")
    f.healthBar:SetValue(0)
    f.powerBar:SetValue(0)
    f.castBar:Hide()
    f.castBar.endTime = nil
    f.auraOverlay:Hide()
    f:SetAlpha(1)
    f:Hide()
end

-------------------------------------------------------------------------------
-- Layout / visibility
-------------------------------------------------------------------------------

-- Live-resize all frames from current settings (frames are insecure, so
-- this is safe at any time; no /reload needed).
function Frames:ApplySizes()
    local cfg = AA.db.profile.frames
    local powerH = cfg.showPowerBar and cfg.powerBarHeight or 0
    local castH = AA.db.profile.castbar.height
    for i = 1, AA.MAX_ARENA_OPPONENTS do
        local f = frames[i]
        f:SetSize(cfg.width + cfg.height, cfg.height)
        f.classIcon:SetSize(cfg.height, cfg.height)
        f.healthBar:SetSize(cfg.width, cfg.height - powerH - 1)
        f.powerBar:SetSize(cfg.width, math.max(powerH - 1, 1))
        f.powerBar:SetShown(cfg.showPowerBar)
        f.castBar:SetSize(cfg.width - castH, castH)
        f.castBar.icon:SetSize(castH, castH)
        if not AA.db.profile.castbar.enabled then
            f.castBar.endTime = nil
            f.castBar:Hide()
        end
        self:ApplyTextLayout(f)
    end
    self:Layout()
end

function Frames:Layout()
    local cfg = AA.db.profile.frames
    for i = 1, AA.MAX_ARENA_OPPONENTS do
        local f = frames[i]
        f:ClearAllPoints()
        local yOff = (cfg.height + cfg.spacing) * (i - 1)
        if cfg.growDown then
            f:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -8 - yOff)
        else
            f:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, 8 + yOff)
        end
        f:SetScale(cfg.scale)
    end
end

function Frames:UpdateLockState()
    if AA.db.profile.locked then
        StopMovingAnchor()
        anchor.bg:Hide()
        anchor.label:Hide()
        anchor:EnableMouse(false)
    else
        anchor.bg:Show()
        anchor.label:Show()
        anchor:EnableMouse(true)
    end
end

-------------------------------------------------------------------------------
-- Data updates
-------------------------------------------------------------------------------

function Frames:SetFrameClass(f, classToken)
    local coords = AA.CLASS_ICON_TCOORDS[classToken]
    if coords then
        f.classIcon:SetTexture(CLASS_ICONS)
        f.classIcon:SetTexCoord(unpack(coords))
    else
        f.classIcon:SetTexCoord(0, 1, 0, 1)
    end
    if AA.db.profile.frames.classColoredHealth then
        f.healthBar:SetStatusBarColor(AA.ClassColor(classToken))
    else
        f.healthBar:SetStatusBarColor(0.2, 0.8, 0.2)
    end
end

local function Abbrev(v)
    if v >= 1000 then
        return ("%.1fk"):format(v / 1000)
    end
    return tostring(v)
end

-- "11.0k (99%)", "11.0k", "99%", or "" per the configured mode.
function AA.FormatBarText(mode, cur, max)
    if mode == "none" or not max or max <= 0 then return "" end
    local pct = math.floor(cur / max * 100 + 0.5)
    if mode == "value" then return Abbrev(cur) end
    if mode == "percent" then return pct .. "%" end
    return ("%s (%d%%)"):format(Abbrev(cur), pct)
end

function Frames:UpdateUnit(f)
    if AA.testMode then return end
    local unit = f.unit

    if not UnitExists(unit) then
        -- Stealthed / vanished / out of detection range: keep the frame with
        -- its last-known data, just dim it so the state is readable.
        if f.seen and AA.inArena then
            if not f:IsShown() then f:Show() end
            f:SetAlpha(STEALTH_ALPHA)
        end
        return
    end

    -- First sighting this match: reveal the frame (insecure, combat-safe).
    if AA.inArena and not f.seen then
        f.seen = true
        f:Show()
    end
    f:SetAlpha(1)

    local _, classToken = UnitClass(unit)
    classToken = classToken or AA.unitClass[unit]
    if classToken and f.classToken ~= classToken then
        f.classToken = classToken
        self:SetFrameClass(f, classToken)
    end

    if AA.db.profile.frames.showNames then
        local name = AA.StripRealm(UnitName(unit))
        if name and name ~= UNKNOWNOBJECT then
            f.nameText:SetText(name)
        end
    else
        f.nameText:SetText("")
    end

    local cfg = AA.db.profile.frames

    local hp, hpMax = UnitHealth(unit), UnitHealthMax(unit)
    if hpMax and hpMax > 0 then
        f.healthBar:SetValue(hp / hpMax)
        f.healthText:SetText(AA.FormatBarText(cfg.healthTextMode, hp, hpMax))
    end

    if cfg.showPowerBar then
        local power, powerMax = UnitPower(unit), UnitPowerMax(unit)
        local _, powerToken = UnitPowerType(unit)
        local pc = AA.POWER_COLORS[powerToken] or AA.POWER_COLORS.MANA
        f.powerBar:SetStatusBarColor(pc[1], pc[2], pc[3])
        if powerMax and powerMax > 0 then
            f.powerBar:SetValue(power / powerMax)
            f.powerText:SetText(AA.FormatBarText(cfg.powerTextMode, power, powerMax))
        end
    end

    if UnitIsDeadOrGhost(unit) then
        f.healthBar:SetValue(0)
        f.healthText:SetText(DEAD or "Dead")
    end
end

-- How many opponents this match should have. Rated games report the team
-- size via battlefield status; skirmishes often report 0, so anything we've
-- identified indirectly (GUID map, cached classes) raises the count.
local function ExpectedOpponents()
    local count = 0
    if GetBattlefieldStatus then
        for i = 1, (GetMaxBattlefieldID and GetMaxBattlefieldID() or 3) do
            local status, _, _, _, _, teamSize = GetBattlefieldStatus(i)
            if status == "active" and teamSize and teamSize > 0 then
                count = teamSize
                break
            end
        end
    end
    for unit in pairs(AA.unitClass) do
        local i = AA.ArenaIndex(unit)
        if i and i > count then count = i end
    end
    for _, unit in pairs(AA.guidToUnit) do
        local i = AA.ArenaIndex(unit)
        if i and i > count then count = i end
    end
    return math.min(count, AA.MAX_ARENA_OPPONENTS)
end

function Frames:UpdateAll()
    if not AA.inArena or AA.testMode then return end
    local expected = ExpectedOpponents()
    for i = 1, AA.MAX_ARENA_OPPONENTS do
        local f = frames[i]
        -- Every expected opponent gets a row from the start of the match -
        -- stealthed enemies show as a placeholder until first sighting, so a
        -- row can never be missing.
        if i <= expected and not f.seen and not f.prefilled then
            f.prefilled = true
            ApplyPlaceholder(f)
            f:Show()
        end
        self:UpdateUnit(f)
    end
end

-------------------------------------------------------------------------------
-- Cast bar events
-------------------------------------------------------------------------------

function Frames:StartCast(unit, channeling)
    local i = AA.ArenaIndex(unit)
    if not i or not AA.db.profile.castbar.enabled then return end
    local f = frames[i]

    local name, text, texture, startMS, endMS
    if channeling then
        name, text, texture, startMS, endMS = AA.UnitChannelInfoCompat(unit)
    else
        name, text, texture, startMS, endMS = AA.UnitCastingInfoCompat(unit)
    end
    if not name then return end

    f.castBar.startTime = startMS / 1000
    f.castBar.endTime = endMS / 1000
    f.castBar.channeling = channeling
    f.castBar.text:SetText(text or name)
    f.castBar.icon:SetTexture(texture)
    f.castBar:Show()
end

function Frames:StopCast(unit)
    local i = AA.ArenaIndex(unit)
    if not i then return end
    frames[i].castBar.endTime = nil
    frames[i].castBar:Hide()
end

function Frames:OnCastEvent(event, unit)
    if not unit or not unit:match("^arena%d$") then return end
    if event == "UNIT_SPELLCAST_START" then
        self:StartCast(unit, false)
    elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
        self:StartCast(unit, true)
    elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP"
        or event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED" then
        self:StopCast(unit)
    end
end

-------------------------------------------------------------------------------
-- Arena lifecycle
-------------------------------------------------------------------------------

function Frames:OnArenaJoined()
    for i = 1, AA.MAX_ARENA_OPPONENTS do
        ClearFrame(frames[i])
    end
    self:UpdateAll()
end

function Frames:OnArenaLeft()
    if AA.testMode then return end
    for i = 1, AA.MAX_ARENA_OPPONENTS do
        ClearFrame(frames[i])
    end
end

function Frames:OnOpponentUpdate(_, unit)
    local i = AA.ArenaIndex(unit)
    if i then
        self:UpdateUnit(frames[i])
    end
end

-------------------------------------------------------------------------------
-- Module lifecycle
-------------------------------------------------------------------------------

function Frames:OnInitialize()
    CreateAnchor()
    for i = 1, AA.MAX_ARENA_OPPONENTS do
        frames[i] = CreateUnitFrame(i)
    end
    self:Layout()
    self:UpdateLockState()
    addon:SendMessage("AA_FRAMES_CREATED")
end

function Frames:OnEnable()
    self:RegisterMessage("AA_ARENA_JOINED", "OnArenaJoined")
    self:RegisterMessage("AA_ARENA_LEFT", "OnArenaLeft")
    self:RegisterMessage("AA_OPPONENT_UPDATE", "OnOpponentUpdate")

    self:RegisterEvent("UNIT_HEALTH", "OnUnitEvent")
    self:RegisterEvent("UNIT_MAXHEALTH", "OnUnitEvent")
    self:RegisterEvent("UNIT_POWER_UPDATE", "OnUnitEvent")
    self:RegisterEvent("UNIT_NAME_UPDATE", "OnUnitEvent")

    self:RegisterEvent("UNIT_SPELLCAST_START", "OnCastEvent")
    self:RegisterEvent("UNIT_SPELLCAST_STOP", "OnCastEvent")
    self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START", "OnCastEvent")
    self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP", "OnCastEvent")
    self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", "OnCastEvent")
    self:RegisterEvent("UNIT_SPELLCAST_FAILED", "OnCastEvent")

    -- Safety net: catches units appearing/vanishing without discrete events
    -- (stealth in/out, gates opening) and keeps bars fresh.
    self:ScheduleRepeatingTimer("UpdateAll", 0.5)
end

function Frames:OnUnitEvent(_, unit)
    local i = AA.ArenaIndex(unit)
    if i then
        self:UpdateUnit(frames[i])
    end
end

function AA.GetFrame(i)
    return frames[i]
end
