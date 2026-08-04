-- Per-character honor / arena points / BG marks snapshot for the desktop
-- companion to upload to arenaarmory.com (Upgrades affordability).
-- Persisted in ArenaArmoryCurrency (account-wide SavedVariables).
local _, AA = ...
local addon = AA.addon

local Currency = addon:NewModule("Currency", "AceEvent-3.0", "AceTimer-3.0")
AA.Currency = Currency

local SCHEMA_VERSION = 1

-- TBC Mark of Honor item IDs (wowhead.com/tbc + Anniversary).
local MARK_ITEMS = {
    wsg = 20558, -- Warsong Gulch
    ab = 20559,  -- Arathi Basin
    av = 20560,  -- Alterac Valley
    eots = 29024, -- Eye of the Storm
}

-- Anniversary (2.5.x) removed GetHonorCurrency/GetArenaCurrency; honor/AP are
-- currencies 1901/1900 via C_CurrencyInfo (Constants.CurrencyConsts).
local HONOR_CURRENCY_ID = (Constants and Constants.CurrencyConsts
    and Constants.CurrencyConsts.CLASSIC_HONOR_CURRENCY_ID) or 1901
local ARENA_CURRENCY_ID = (Constants and Constants.CurrencyConsts
    and Constants.CurrencyConsts.CLASSIC_ARENA_POINTS_CURRENCY_ID) or 1900

local function QuantityFromCurrencyId(id)
    if C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo then
        local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfo, id)
        if ok and type(info) == "table" and type(info.quantity) == "number" and info.quantity >= 0 then
            return math.floor(info.quantity)
        end
    end
    if type(GetCurrencyInfo) == "function" then
        local ok, name, amount = pcall(GetCurrencyInfo, id)
        if ok and type(amount) == "number" and amount >= 0 then
            return math.floor(amount)
        end
        if ok and type(name) == "number" and name >= 0 then
            return math.floor(name)
        end
    end
    return nil
end

local function GetHonorPoints()
    local qty = QuantityFromCurrencyId(HONOR_CURRENCY_ID)
    if qty ~= nil then return qty end
    if type(GetHonorCurrency) == "function" then
        local ok, value = pcall(GetHonorCurrency)
        if ok and type(value) == "number" and value >= 0 then
            return math.floor(value)
        end
    end
    return 0
end

local function GetArenaPoints()
    local qty = QuantityFromCurrencyId(ARENA_CURRENCY_ID)
    if qty ~= nil then return qty end
    if type(GetArenaCurrency) == "function" then
        local ok, value = pcall(GetArenaCurrency)
        if ok and type(value) == "number" and value >= 0 then
            return math.floor(value)
        end
    end
    return 0
end

local function TryCount(fn, itemId, includeBank)
    if type(fn) ~= "function" then return nil end
    local ok, count = pcall(fn, itemId, includeBank)
    if ok and type(count) == "number" and count >= 0 then
        return math.floor(count)
    end
    return nil
end

local function BagNumSlots(bag)
    if C_Container and C_Container.GetContainerNumSlots then
        local ok, n = pcall(C_Container.GetContainerNumSlots, bag)
        if ok and type(n) == "number" then return n end
    end
    if type(GetContainerNumSlots) == "function" then
        local ok, n = pcall(GetContainerNumSlots, bag)
        if ok and type(n) == "number" then return n end
    end
    return 0
end

local function BagItemId(bag, slot)
    if C_Container and C_Container.GetContainerItemID then
        local ok, id = pcall(C_Container.GetContainerItemID, bag, slot)
        if ok and type(id) == "number" then return id end
    end
    if type(GetContainerItemID) == "function" then
        local ok, id = pcall(GetContainerItemID, bag, slot)
        if ok and type(id) == "number" then return id end
    end
    if type(GetContainerItemLink) == "function" then
        local ok, link = pcall(GetContainerItemLink, bag, slot)
        if ok and type(link) == "string" then
            local id = tonumber(link:match("item:(%d+)"))
            if id then return id end
        end
    end
    return nil
end

local function BagStackCount(bag, slot)
    if C_Container and C_Container.GetContainerItemInfo then
        local ok, info = pcall(C_Container.GetContainerItemInfo, bag, slot)
        if ok and type(info) == "table" then
            local n = info.stackCount or info.quantity
            if type(n) == "number" then return n end
        end
    end
    if type(GetContainerItemInfo) == "function" then
        -- Classic: texture, count, locked, quality, readable, lootable, link, ...
        local ok, _, count = pcall(GetContainerItemInfo, bag, slot)
        if ok and type(count) == "number" then return count end
    end
    return 1
end

-- Bags 0–4 (backpack + four bag slots). Bank omitted unless bank UI is open.
local function CountMarkInBags(itemId)
    local total = 0
    for bag = 0, 4 do
        local slots = BagNumSlots(bag)
        for slot = 1, slots do
            if BagItemId(bag, slot) == itemId then
                total = total + BagStackCount(bag, slot)
            end
        end
    end
    return total
end

local function CountMark(itemId)
    if type(itemId) ~= "number" then return 0 end

    -- Anniversary / modern clients prefer C_Item; legacy GetItemCount may error
    -- or return 0 before bags are ready.
    local n = TryCount(C_Item and C_Item.GetItemCount, itemId, true)
        or TryCount(C_Item and C_Item.GetItemCount, itemId, false)
        or TryCount(GetItemCount, itemId, true)
        or TryCount(GetItemCount, itemId, false)
        or 0

    if n <= 0 then
        n = CountMarkInBags(itemId)
    end
    return n
end

local function NowMs()
    local t = time()
    if type(t) ~= "number" then return 0 end
    return t * 1000
end

local function MarksAllZero(marks)
    return (marks.av or 0) == 0 and (marks.wsg or 0) == 0
        and (marks.ab or 0) == 0 and (marks.eots or 0) == 0
end

-- Bags aren't guaranteed cached yet when these fire (login / zone-in), so a
-- mark read here can come back all-zero even though the character actually
-- has marks - CountMark just returns 0 for "nothing found" whether that
-- means "really zero" or "bags not scanned yet" (see comment on OnEnable).
local UNSAFE_MARK_REASONS = {
    enable = true,
    enter = true,
}

function Currency:EnsureDB()
    ArenaArmoryCurrency = ArenaArmoryCurrency or {}
    ArenaArmoryCurrency.schemaVersion = SCHEMA_VERSION
    ArenaArmoryCurrency.characters = ArenaArmoryCurrency.characters or {}
end

function Currency:Snapshot(reason)
    self:EnsureDB()

    local name = AA.StripRealm(UnitName("player"))
    local realm = GetRealmName and GetRealmName() or ""
    local key = AA.CharKey(name, realm)
    if not key then return nil end

    local prior = ArenaArmoryCurrency.characters[key]

    local marks = {
        av = CountMark(MARK_ITEMS.av),
        wsg = CountMark(MARK_ITEMS.wsg),
        ab = CountMark(MARK_ITEMS.ab),
        eots = CountMark(MARK_ITEMS.eots),
    }
    -- Don't let a bag-cache-not-ready read of "everything is 0" stomp a real
    -- prior mark count - keep the last known marks and let the debounced
    -- bag-refresh snapshot (reason "bags") correct them once bags are ready.
    if prior and prior.marks and UNSAFE_MARK_REASONS[reason]
        and MarksAllZero(marks) and not MarksAllZero(prior.marks) then
        marks = prior.marks
    end

    local snapshot = {
        honor = GetHonorPoints(),
        arenaPoints = GetArenaPoints(),
        marks = marks,
        updatedAt = NowMs(),
        name = name,
        realm = realm,
    }

    if prior and type(prior.updatedAt) == "number" and prior.updatedAt > snapshot.updatedAt then
        return prior
    end

    ArenaArmoryCurrency.characters[key] = snapshot
    self.lastSnapshot = snapshot
    self.lastKey = key
    self.lastReason = reason
    return snapshot
end

--- Opt-in status (`/aa currency`). One line; no API/source debug spam.
function Currency:DebugPrint()
    local snap = self:Snapshot("slash")
    if not snap then
        addon:Print("Currency: could not build charKey (missing name/realm).")
        return
    end
    addon:Print(("Currency (%s): honor=%d AP=%d · AV=%d WSG=%d AB=%d EotS=%d")
        :format(
            self.lastKey or "?",
            snap.honor or 0,
            snap.arenaPoints or 0,
            snap.marks.av or 0,
            snap.marks.wsg or 0,
            snap.marks.ab or 0,
            snap.marks.eots or 0
        ))
end

function Currency:OnMatchRecorded()
    self:Snapshot("match")
end

function Currency:OnLogout()
    self:Snapshot("logout")
end

function Currency:OnBankOpened()
    self:Snapshot("bank")
end

function Currency:ScheduleBagRefresh()
    if self.bagTimer then
        self:CancelTimer(self.bagTimer, true)
        self.bagTimer = nil
    end
    -- Bags often empty for a beat after login /reload; debounce BAG_UPDATE.
    self.bagTimer = self:ScheduleTimer(function()
        self.bagTimer = nil
        if self:IsEnabled() then
            self:Snapshot("bags")
        end
    end, 0.75)
end

function Currency:OnBagUpdate()
    self:ScheduleBagRefresh()
end

function Currency:OnEnteringWorld()
    self:Snapshot("enter")
    self:ScheduleBagRefresh()
end

function Currency:OnInitialize()
    self:EnsureDB()
end

function Currency:OnEnable()
    self:EnsureDB()
    self:RegisterMessage("AA_MATCH_RECORDED", "OnMatchRecorded")
    self:RegisterEvent("PLAYER_LOGOUT", "OnLogout")
    self:RegisterEvent("BANKFRAME_OPENED", "OnBankOpened")
    self:RegisterEvent("BAG_UPDATE", "OnBagUpdate")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEnteringWorld")
    -- Immediate capture for honor/AP; marks usually fill on the bag refresh.
    self:Snapshot("enable")
    self:ScheduleBagRefresh()
end

function Currency:OnDisable()
    if self.bagTimer then
        self:CancelTimer(self.bagTimer, true)
        self.bagTimer = nil
    end
end
