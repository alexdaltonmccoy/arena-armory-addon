-- Website integration: copy-URL dialog (the WoW sandbox can't open a
-- browser), /aa web + /aa lookup commands, shift-click character lookup from
-- the enemy frames, and the clickable post-match chat link.
local _, AA = ...
local addon = AA.addon

local WebLink = addon:NewModule("WebLink")
AA.WebLink = WebLink

AA.SITE_URL = "https://arenaarmory.com"

-- Mirrors the site's slugify(): lowercase, apostrophes removed, runs of
-- non-alphanumerics collapsed to "-", leading/trailing dashes trimmed.
function AA.Slugify(s)
    if not s then return "" end
    s = s:lower()
    s = s:gsub("['\226\128\153]", "")  -- ' and the UTF-8 right single quote
    s = s:gsub("[^%w]+", "-")
    s = s:gsub("^%-+", ""):gsub("%-+$", "")
    return s
end

function AA.CharacterURL(name, realm)
    return ("%s/character/%s/%s"):format(AA.SITE_URL, AA.Slugify(realm), AA.Slugify(name))
end

-------------------------------------------------------------------------------
-- Copy-URL dialog
-------------------------------------------------------------------------------

local dialog

local function EnsureDialog()
    if dialog then return dialog end

    dialog = CreateFrame("Frame", "ArenaArmoryCopyDialog", UIParent,
        BackdropTemplateMixin and "BackdropTemplate" or nil)
    dialog:SetSize(440, 120)
    dialog:SetPoint("CENTER", 0, 180)
    dialog:SetFrameStrata("DIALOG")
    dialog:SetMovable(true)
    dialog:EnableMouse(true)
    dialog:RegisterForDrag("LeftButton")
    dialog:SetScript("OnDragStart", dialog.StartMoving)
    dialog:SetScript("OnDragStop", dialog.StopMovingOrSizing)
    if dialog.SetBackdrop then
        dialog:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 8, right = 8, top = 8, bottom = 8 },
        })
    end

    dialog.title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dialog.title:SetPoint("TOP", 0, -16)

    dialog.hint = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    dialog.hint:SetPoint("TOP", dialog.title, "BOTTOM", 0, -4)
    dialog.hint:SetText("Press Ctrl+C to copy, then paste in your browser. Esc to close.")

    local box = CreateFrame("EditBox", nil, dialog, "InputBoxTemplate")
    box:SetSize(390, 20)
    box:SetPoint("TOP", dialog.hint, "BOTTOM", 0, -12)
    box:SetAutoFocus(true)
    box:SetScript("OnEscapePressed", function() dialog:Hide() end)
    box:SetScript("OnEnterPressed", function() dialog:Hide() end)
    -- Keep the URL intact: any user edit restores the text and re-selects it,
    -- so Ctrl+C always copies the full link.
    box:SetScript("OnTextChanged", function(self, userInput)
        if userInput then
            self:SetText(dialog.url or "")
            self:HighlightText()
        end
    end)
    box:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    dialog.box = box

    local close = CreateFrame("Button", nil, dialog, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)

    return dialog
end

function AA.ShowCopyDialog(url, title)
    local d = EnsureDialog()
    d.url = url
    d.title:SetText(title or "Arena Armory")
    d.box:SetText(url)
    d:Show()
    d.box:SetFocus()
    d.box:HighlightText()
end

-------------------------------------------------------------------------------
-- Character lookup
-------------------------------------------------------------------------------

function AA.LookupUnit(unit)
    if not UnitExists(unit) or not UnitIsPlayer(unit) then
        addon:Print("No player to look up.")
        return
    end
    local name, realm = UnitName(unit)
    if not name then return end
    if not realm or realm == "" then
        realm = GetRealmName and GetRealmName() or ""
    end
    AA.ShowCopyDialog(AA.CharacterURL(name, realm), name .. " on arenaarmory.com")
end

-- Accepts "Name" (player's realm assumed) or "Name-Realm".
function AA.LookupName(input)
    local name, realm = input:match("^([^%-]+)%-?(.*)$")
    if not name or name == "" then
        addon:Print("Usage: /aa lookup Name or /aa lookup Name-Realm")
        return
    end
    if realm == "" then
        realm = GetRealmName and GetRealmName() or ""
    end
    AA.ShowCopyDialog(AA.CharacterURL(name, realm), name .. " on arenaarmory.com")
end

-------------------------------------------------------------------------------
-- Clickable chat links (modern "addon" hyperlink type)
-------------------------------------------------------------------------------

function AA.MatchesChatLink()
    return "|Haddon:ArenaArmory:matches|h|cff4fc3f7[arenaarmory.com]|r|h"
end

local function HandleLink(link)
    local linkType, ns, payload = strsplit(":", link or "")
    if linkType ~= "addon" or ns ~= "ArenaArmory" then return end
    if payload == "matches" then
        AA.ShowCopyDialog(AA.SITE_URL .. "/matches", "Your matches on arenaarmory.com")
    else
        AA.ShowCopyDialog(AA.SITE_URL, "arenaarmory.com")
    end
end

function WebLink:OnEnable()
    if EventRegistry and EventRegistry.RegisterCallback then
        EventRegistry:RegisterCallback("SetItemRef", function(_, link)
            HandleLink(link)
        end, WebLink)
    elseif type(SetItemRef) == "function" then
        hooksecurefunc("SetItemRef", HandleLink)
    end
end
