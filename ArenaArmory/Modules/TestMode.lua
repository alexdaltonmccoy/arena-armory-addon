-- Test mode: fake opponents outside arena for layout/config work.
local _, AA = ...
local addon = AA.addon

local TestMode = addon:NewModule("TestMode", "AceEvent-3.0", "AceTimer-3.0")
AA.TestMode = TestMode

local TEST_CAST = { spellId = 12826, duration = 10 } -- Polymorph

local function ApplyTestData(i, opp)
    local f = AA.GetFrame(i)
    if not f then return end

    local cfg = AA.db.profile.frames
    f.classToken = opp.class
    AA.Frames:SetFrameClass(f, opp.class)
    f.nameText:SetText(cfg.showNames and opp.name or "")
    f.specText:SetText(opp.race and (opp.spec .. " " .. opp.race) or opp.spec)

    -- Plausible TBC pools so the value/percent text modes preview correctly.
    local hpMax, powerMax = 11000, 10500
    f.healthBar:SetValue(opp.health)
    f.healthText:SetText(AA.FormatBarText(cfg.healthTextMode, opp.health * hpMax, hpMax))

    local pc = AA.POWER_COLORS[opp.powerType] or AA.POWER_COLORS.MANA
    f.powerBar:SetStatusBarColor(pc[1], pc[2], pc[3])
    f.powerBar:SetValue(opp.power)
    f.powerText:SetText(AA.FormatBarText(cfg.powerTextMode, opp.power * powerMax, powerMax))

    f:Show()
end

function TestMode:StartFakeCast(i)
    if not AA.testMode or not AA.db.profile.castbar.enabled then return end
    local f = AA.GetFrame(i)
    if not f then return end
    local now = GetTime()
    f.castBar.startTime = now
    f.castBar.endTime = now + TEST_CAST.duration
    f.castBar.channeling = false
    f.castBar.text:SetText(AA.GetSpellName(TEST_CAST.spellId) or "Polymorph")
    f.castBar.icon:SetTexture(AA.GetSpellTexture(TEST_CAST.spellId))
    f.castBar:Show()
end

function TestMode:Toggle()
    if AA.testMode then
        self:Disable_()
    else
        self:Enable_()
    end
end

local function ApplyAllTestData()
    for i, opp in ipairs(AA.TEST_OPPONENTS) do
        local unit = "arena" .. i
        AA.unitClass[unit] = opp.class

        ApplyTestData(i, opp)

        if AA.Trinket and AA.db.profile.trinket.enabled and i <= 2 then
            AA.Trinket:StartCooldown(i, 42292, 120)
            -- The test rogue is Undead: preview the separate WotF icon too.
            if i == 1 then AA.Trinket:StartCooldown(i, 7744, 120) end
        end
        if AA.DR and AA.db.profile.dr.enabled then
            AA.DR:Handle(i, "stun", 8643, false)
            AA.DR:Handle(i, "stun", 8643, true)
            if i % 2 == 0 then
                AA.DR:Handle(i, "incapacitate", 12826, false)
                AA.DR:Handle(i, "incapacitate", 12826, true)
                AA.DR:Handle(i, "incapacitate", 12826, false)
                AA.DR:Handle(i, "incapacitate", 12826, true)
            end
        end
        if AA.Cooldowns and AA.db.profile.cooldowns.enabled then
            AA.Cooldowns:Track(i, 42292, 120)
            AA.Cooldowns:Track(i, ({6552, 10308, 19503, 38768, 10890})[i] or 6552,
                ({10, 60, 30, 10, 30})[i] or 30)
        end
    end
end

-- Re-applies all fake data; used when options change while test mode is on
-- so re-enabled trackers get their sample icons back.
function TestMode:Refresh()
    if not AA.testMode then return end
    if AA.Trinket then AA.Trinket:Reset() end
    if AA.DR then AA.DR:Reset() end
    if AA.Cooldowns then AA.Cooldowns:Reset() end
    ApplyAllTestData()
    self:StartFakeCast(2)
end

function TestMode:Enable_()
    if AA.inArena then
        addon:Print("Cannot enable test mode inside an arena.")
        return
    end
    if InCombatLockdown() then
        addon:Print("Cannot enable test mode in combat.")
        return
    end

    AA.testMode = true
    ApplyAllTestData()
    self:StartFakeCast(2)
    self.castTimer = self:ScheduleRepeatingTimer(function() TestMode:StartFakeCast(2) end, TEST_CAST.duration + 2)
    addon:Print("Test mode ON. Type /aa test again to hide.")
end

function TestMode:Disable_()
    AA.testMode = false
    if self.castTimer then
        self:CancelTimer(self.castTimer)
        self.castTimer = nil
    end
    if AA.Trinket then AA.Trinket:Reset() end
    if AA.DR then AA.DR:Reset() end
    if AA.Cooldowns then AA.Cooldowns:Reset() end
    for i = 1, AA.MAX_ARENA_OPPONENTS do
        local f = AA.GetFrame(i)
        if f then
            f:Hide()
            f.classToken = nil
            f.castBar:Hide()
            f.auraOverlay:Hide()
            f.specText:SetText("")
        end
        AA.unitClass["arena" .. i] = nil
    end
    addon:Print("Test mode OFF.")
end
