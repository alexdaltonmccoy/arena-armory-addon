-- Minimap launcher icon: LibDataBroker object + LibDBIcon button. Purely a
-- discoverability aid (open options / stats without remembering /aa) - no
-- gameplay logic lives here.
local _, AA = ...
local addon = AA.addon

local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local Minimap = addon:NewModule("Minimap")
AA.Minimap = Minimap

local dataObject = LDB:NewDataObject("ArenaArmory", {
    type = "launcher",
    icon = "Interface\\AddOns\\ArenaArmory\\Media\\Logo.png",
    OnClick = function(_, button)
        if button == "RightButton" then
            if AA.Analytics then AA.Analytics:Toggle() end
        else
            AceConfigDialog:Open("ArenaArmory")
        end
    end,
    OnTooltipShow = function(tooltip)
        if not tooltip or not tooltip.AddLine then return end
        tooltip:AddLine("Arena Armory")
        tooltip:AddLine(("v%s"):format(AA.version), 0.7, 0.7, 0.7)
        tooltip:AddLine(" ")
        tooltip:AddLine("|cffffffffLeft-click:|r options", 0.9, 0.9, 0.9)
        tooltip:AddLine("|cffffffffRight-click:|r stats panel", 0.9, 0.9, 0.9)
    end,
})
AA.minimapLDB = dataObject

function Minimap:OnInitialize()
    LDBIcon:Register("ArenaArmory", dataObject, AA.db.profile.minimap)
end

-- Shared by the options checkbox and /aa minimap.
function Minimap:SetShown(shown)
    AA.db.profile.minimap.hide = not shown
    if shown then
        LDBIcon:Show("ArenaArmory")
    else
        LDBIcon:Hide("ArenaArmory")
    end
end
