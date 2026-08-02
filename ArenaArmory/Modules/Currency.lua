-- Per-character honor / arena points / BG marks snapshot for the desktop
-- companion to upload to arenaarmory.com (Upgrades affordability).
-- Persisted in ArenaArmoryCurrency (account-wide SavedVariables).
local _, AA = ...
local addon = AA.addon

local Currency = addon:NewModule("Currency", "AceEvent-3.0")
AA.Currency = Currency

local SCHEMA_VERSION = 1

-- TBC Mark of Honor item IDs (verified vs wowhead.com/tbc).
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
    -- Legacy GetCurrencyInfo(id) -> name, amount, ...
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

local function CountMark(itemId)
    if type(GetItemCount) ~= "function" or type(itemId) ~= "number" then return 0 end
    -- includeBank=true when the bank has been opened this session; otherwise bags only.
    local ok, count = pcall(GetItemCount, itemId, true)
    if not ok or type(count) ~= "number" or count < 0 then return 0 end
    return math.floor(count)
end

local function NowMs()
    -- Match site Date.now() milliseconds so newest-wins works across sources.
    local t = time()
    if type(t) ~= "number" then return 0 end
    return t * 1000
end

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

    local snapshot = {
        honor = GetHonorPoints(),
        arenaPoints = GetArenaPoints(),
        marks = {
            av = CountMark(MARK_ITEMS.av),
            wsg = CountMark(MARK_ITEMS.wsg),
            ab = CountMark(MARK_ITEMS.ab),
            eots = CountMark(MARK_ITEMS.eots),
        },
        updatedAt = NowMs(),
        name = name,
        realm = realm,
    }

    local prior = ArenaArmoryCurrency.characters[key]
    if prior and type(prior.updatedAt) == "number" and prior.updatedAt > snapshot.updatedAt then
        -- Clock skew / double fire: never write an older stamp.
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
    -- Refresh mark counts once the bank cache is available.
    self:Snapshot("bank")
end

function Currency:OnInitialize()
    self:EnsureDB()
end

function Currency:OnEnable()
    self:EnsureDB()
    self:RegisterMessage("AA_MATCH_RECORDED", "OnMatchRecorded")
    self:RegisterEvent("PLAYER_LOGOUT", "OnLogout")
    self:RegisterEvent("BANKFRAME_OPENED", "OnBankOpened")
    -- Capture on load so /reload alone is enough for local desktop testing.
    self:Snapshot("enable")
end
