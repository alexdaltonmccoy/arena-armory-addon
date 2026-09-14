-- Important aura (CC/immunity) overlay on the class icon.
local _, AA = ...
local addon = AA.addon

local Auras = addon:NewModule("Auras", "AceEvent-3.0")
AA.Auras = Auras

function Auras:OnEnable()
    self:RegisterMessage("AA_UNIT_AURA", "OnUnitAura")
    self:RegisterMessage("AA_ARENA_LEFT", "ClearAll")
end

function Auras:ClearAll()
    for i = 1, AA.MAX_ARENA_OPPONENTS do
        local f = AA.GetFrame(i)
        if f then f.auraOverlay:Hide() end
    end
end

function Auras:ApplyOptions()
    if not AA.db.profile.auras.enabled then
        self:ClearAll()
    end
end

local function BestImportantAura(list)
    local bestPrio, bestIcon, bestDuration, bestExpiration
    for _, aura in ipairs(list) do
        local prio = aura.spellId and AA.IMPORTANT_AURAS[aura.spellId]
        if prio and (not bestPrio or prio > bestPrio) then
            bestPrio, bestIcon, bestDuration, bestExpiration = prio, aura.icon, aura.duration, aura.expirationTime
        end
    end
    return bestPrio, bestIcon, bestDuration, bestExpiration
end

function Auras:OnUnitAura(_, unit, helpful, harmful)
    local i = AA.ArenaIndex(unit)
    if not i or not AA.db.profile.auras.enabled then return end
    local f = AA.GetFrame(i)
    if not f or not f:IsShown() then return end

    local dPrio, dIcon, dDur, dExp = BestImportantAura(harmful)
    local bPrio, bIcon, bDur, bExp = BestImportantAura(helpful)

    local prio, icon, duration, expirationTime
    if dPrio and (not bPrio or dPrio >= bPrio) then
        prio, icon, duration, expirationTime = dPrio, dIcon, dDur, dExp
    else
        prio, icon, duration, expirationTime = bPrio, bIcon, bDur, bExp
    end

    if prio and icon then
        f.auraOverlay.icon:SetTexture(icon)
        if duration and duration > 0 and expirationTime then
            f.auraOverlay.cooldown:SetCooldown(expirationTime - duration, duration)
        else
            f.auraOverlay.cooldown:Clear()
        end
        f.auraOverlay:Show()
    else
        f.auraOverlay:Hide()
    end
end
