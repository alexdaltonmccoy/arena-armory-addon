-- Audio announcer (GladiatorlosSA-style) using shipped Media/Voice/*.ogg clips.
-- Optional TTS remains as a fallback for users who want it.
local _, AA = ...
local addon = AA.addon

local Announcer = addon:NewModule("Announcer", "AceEvent-3.0")
AA.Announcer = Announcer

local lastSpoken = {}      -- key -> last GetTime() (anti-spam)
local drinkAnnounced = {}  -- arena index -> true while drinking
local lowHpAnnounced = {}  -- arena index -> last announce time

local SPAM_WINDOW = 2.5
local VOICE_PATH = "Interface\\AddOns\\ArenaArmory\\Media\\Voice\\"

-- Session-only; toggled with /aa announcer debug (off by default).
Announcer.debug = false
Announcer.build = "voice1"

function AA.GetTtsVoices()
    if C_VoiceChat and C_VoiceChat.GetTtsVoices then
        return C_VoiceChat.GetTtsVoices() or {}
    end
    return {}
end

function AA.GetTtsVoiceCount()
    return #AA.GetTtsVoices()
end

function Announcer:DebugPrint(msg)
    if not self.debug then return end
    addon:Print("|cff66ccff[Announcer]|r " .. tostring(msg))
end

function Announcer:ResolveVoiceID()
    local voices = AA.GetTtsVoices()
    local valid = {}
    for _, v in ipairs(voices) do
        if v.voiceID then valid[v.voiceID] = true end
    end

    local chosen = tonumber(AA.db.profile.announcer.voice)
    if chosen and valid[chosen] then return chosen end
    if self.workingVoiceID and valid[self.workingVoiceID] then return self.workingVoiceID end
    if C_TTSSettings and C_TTSSettings.GetVoiceOptionID then
        local id = C_TTSSettings.GetVoiceOptionID(0)
        if id and valid[id] then return id end
    end
    local first = voices[1]
    return first and first.voiceID or nil
end

function Announcer:SpeakTTS(msg)
    if not (C_VoiceChat and C_VoiceChat.SpeakText) then return end
    local voiceID = self:ResolveVoiceID()
    if not voiceID then return end
    local rate, volume = 0, 100
    self.lastVoiceID = voiceID
    self.lastMsg = msg
    -- Anniversary / Midnight: SpeakText(voiceID, text, rate, volume)
    if Enum and Enum.VoiceTtsDestination and Enum.VoiceTtsDestination.LocalPlayback
        and self.ttsApi == "legacy" then
        local dest = Enum.VoiceTtsDestination.QueuedLocalPlayback
            or Enum.VoiceTtsDestination.LocalPlayback or 1
        C_VoiceChat.SpeakText(voiceID, msg, dest, rate, volume)
    else
        self.ttsApi = "modern"
        C_VoiceChat.SpeakText(voiceID, msg, rate, volume)
    end
end

function Announcer:OnTtsUpdate(_, status)
    local ok = status == 0 or status == 6 or status == 9
    if ok then
        self.workingVoiceID = self.lastVoiceID
        wipe(self.badVoices)
        return
    end
    local msg = self.lastMsg
    if not msg or not self.lastVoiceID then return end
    if self.ttsApi ~= "legacy" and Enum and Enum.VoiceTtsDestination
        and Enum.VoiceTtsDestination.LocalPlayback ~= nil then
        self.ttsApi = "legacy"
        self:SpeakTTS(msg)
        return
    end
    self.badVoices[self.lastVoiceID] = true
    self.lastMsg = nil
    for _, v in ipairs(AA.GetTtsVoices()) do
        if v.voiceID and not self.badVoices[v.voiceID] then
            self:SpeakTTS(msg)
            return
        end
    end
end

-- Play a voice clip by key (Media/Voice/<key>.ogg). Returns true if PlaySoundFile
-- accepted the request (file missing still returns nil/false on some clients).
function Announcer:PlayVoice(soundKey)
    if not soundKey or not PlaySoundFile then return false end
    local path = VOICE_PATH .. soundKey .. ".ogg"
    local channel = (AA.db.profile.announcer.channel) or "Master"
    local willPlay = PlaySoundFile(path, channel)
    self:DebugPrint(("PlaySoundFile build=%s key=%s channel=%s willPlay=%s"):format(
        self.build, tostring(soundKey), tostring(channel), tostring(willPlay)))
    return willPlay and true or false
end

-- Primary announce entry: sound clip + optional TTS + raid warning.
-- `key` is used for anti-spam (usually the sound key).
function Announcer:Announce(soundKey, text, force)
    local cfg = AA.db.profile.announcer
    if not cfg.enabled then
        self:DebugPrint(("Announce skipped (disabled): %s"):format(tostring(soundKey)))
        return
    end

    text = text or (soundKey and AA.VOICE_TEXT and AA.VOICE_TEXT[soundKey]) or soundKey
    local spamKey = soundKey or text
    local now = GetTime()
    if not force and lastSpoken[spamKey] and (now - lastSpoken[spamKey]) < SPAM_WINDOW then
        self:DebugPrint(("Announce skipped (spam): %s"):format(tostring(spamKey)))
        return
    end
    lastSpoken[spamKey] = now

    local played = false
    if cfg.useSounds ~= false and soundKey then
        played = self:PlayVoice(soundKey)
    end

    -- Optional TTS (off by default — Anniversary TTS is unreliable).
    if cfg.useTTS and text then
        self:SpeakTTS(text)
    end

    -- Beep only when voice clip failed / disabled and TTS is off.
    if not played and not cfg.useTTS and cfg.alertSound then
        PlaySound(SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959, "Master")
    end

    if cfg.raidWarning ~= false and text and RaidNotice_AddMessage and RaidWarningFrame then
        RaidNotice_AddMessage(RaidWarningFrame, text, ChatTypeInfo["RAID_WARNING"])
    end

    self:ChatCallout(text, soundKey)
end

function Announcer:ChatCallout(text, soundKey)
    local mode = AA.db.profile.announcer.chatCallout or "off"
    if mode == "off" or not text or text == "" then return end

    -- Party mode only relays the major whitelist (trinket, drinking, walls, etc.).
    -- Everything else (incl. low health) stays self-only.
    if mode == "party" then
        local allowed = soundKey and AA.PARTY_CHAT_SOUNDS and AA.PARTY_CHAT_SOUNDS[soundKey]
        if not allowed then
            mode = "self"
        end
    end

    local msg = "[Arena Armory] " .. text
    if mode == "self" then
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cff66ccff" .. msg .. "|r")
        end
        return
    end
    if mode == "party" then
        if not AA.SendGroupMessage(msg) and DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cff66ccff" .. msg .. "|r")
        end
    end
end

-- Back-compat for /aa announcer test and older call sites.
function Announcer:Speak(msg, force)
    if msg == "Enemy trinket used" or msg == "Trinket" then
        self:Announce("trinket", "Trinket", force)
        return
    end
    -- Best-effort: match voice text -> sound key
    if AA.VOICE_TEXT then
        for key, label in pairs(AA.VOICE_TEXT) do
            if label == msg then
                self:Announce(key, msg, force)
                return
            end
        end
    end
    self:Announce(nil, msg, force)
end

local function OpponentLabel(i)
    local unit = "arena" .. i
    local classToken = AA.unitClass[unit]
    if classToken then
        local classLoc = LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[classToken]
        if classLoc then return classLoc end
    end
    return "Enemy " .. i
end

local function SpellLabel(spellId)
    if not spellId then return "?" end
    local name = AA.GetSpellName and AA.GetSpellName(spellId)
    return name or tostring(spellId)
end

local function CategoryEnabled(cfg, cat)
    if cat == "cooldown" then return cfg.cooldowns ~= false end
    if cat == "interrupt" then return cfg.interrupts end
    return cfg.casts ~= false -- cc / default
end

-------------------------------------------------------------------------------
-- Triggers
-------------------------------------------------------------------------------

function Announcer:OnTrinketUsed(_, i)
    if AA.testMode then
        self:DebugPrint(("trinket ignored in test mode (arena%d)"):format(i or -1))
        return
    end
    if AA.db.profile.announcer.trinket then
        local who = (i and OpponentLabel(i)) or "Enemy"
        self:Announce("trinket", who .. " trinket", true)
    else
        self:DebugPrint(("trinket used arena%d but trinket announce off"):format(i or -1))
    end
end

function Announcer:TryAnnounceSpell(spellId, source)
    local entry = spellId and AA.ANNOUNCE_SPELLS and AA.ANNOUNCE_SPELLS[spellId]
    if not entry then return false end
    local cfg = AA.db.profile.announcer
    if not CategoryEnabled(cfg, entry.cat) then
        self:DebugPrint(("spell %s (%s) skipped cat=%s"):format(
            tostring(spellId), tostring(entry.sound), tostring(entry.cat)))
        return false
    end
    local text = AA.VOICE_TEXT and AA.VOICE_TEXT[entry.sound] or entry.sound
    self:DebugPrint(("announce %s spell=%s via %s"):format(
        tostring(entry.sound), tostring(spellId), tostring(source)))
    self:Announce(entry.sound, text)
    return true
end

function Announcer:OnCastStart(_, unit, _, spellId)
    local i = AA.ArenaIndex(unit)
    if not i then return end

    if self:TryAnnounceSpell(spellId, "CAST_START") then return end

    local resKey = spellId and AA.ANNOUNCE_RES and AA.ANNOUNCE_RES[spellId]
    if resKey and AA.db.profile.announcer.resurrect then
        self:Announce(resKey, AA.VOICE_TEXT and AA.VOICE_TEXT[resKey] or "Resurrect", true)
    end
end

function Announcer:OnCLEU(_, _, subevent, sourceGUID, sourceName, sourceFlags, _, _, _, spellId)
    if subevent ~= "SPELL_CAST_SUCCESS" then return end

    local entry = spellId and AA.ANNOUNCE_SPELLS and AA.ANNOUNCE_SPELLS[spellId]
    local unit = AA.UnitByGUID(sourceGUID)
    local hostile = AA.IsHostilePlayerFlag and AA.IsHostilePlayerFlag(sourceFlags)

    if self.debug and (entry or unit) then
        self:DebugPrint(("CLEU SUCCESS spell=%s (%s) src=%s unit=%s hostile=%s inArena=%s sound=%s"):format(
            tostring(spellId), SpellLabel(spellId),
            tostring(sourceName), tostring(unit), tostring(hostile),
            tostring(AA.inArena), tostring(entry and entry.sound)))
    end

    if self.debug and entry and not unit and AA.inArena and hostile then
        self:DebugPrint(("MISS: %s from %s not in guid map"):format(
            entry.sound, tostring(sourceName)))
    end

    if not entry then
        local resKey = spellId and AA.ANNOUNCE_RES and AA.ANNOUNCE_RES[spellId]
        if resKey and unit and AA.db.profile.announcer.resurrect then
            self:Announce(resKey, AA.VOICE_TEXT and AA.VOICE_TEXT[resKey] or "Resurrect", true)
        end
        return
    end
    if not unit then return end
    self:TryAnnounceSpell(spellId, "CLEU")
end

function Announcer:OnUnitAura(_, unit)
    local i = AA.ArenaIndex(unit)
    if not i or not AA.db.profile.announcer.drink then return end

    local drinking = false
    for index = 1, 40 do
        local name, _, _, _, _, _, _, spellId = AA.GetAuraByIndex(unit, index, "HELPFUL")
        if not name then break end
        if (spellId and AA.DRINK_AURAS[spellId]) or name == AA.DRINK_NAME then
            drinking = true
            break
        end
    end

    if drinking and not drinkAnnounced[i] then
        drinkAnnounced[i] = true
        self:Announce("drinking", OpponentLabel(i) .. " drinking")
    elseif not drinking then
        drinkAnnounced[i] = nil
    end
end

function Announcer:OnUnitHealth(_, unit)
    local i = AA.ArenaIndex(unit)
    if not i then return end
    local cfg = AA.db.profile.announcer
    if not cfg.lowHealth then return end

    local hp, hpMax = UnitHealth(unit), UnitHealthMax(unit)
    if not hpMax or hpMax == 0 or UnitIsDeadOrGhost(unit) then return end

    local now = GetTime()
    if hp / hpMax <= cfg.lowHealthThreshold then
        if not lowHpAnnounced[i] or (now - lowHpAnnounced[i]) > 10 then
            lowHpAnnounced[i] = now
            self:Announce("lowhealth", OpponentLabel(i) .. " low health")
        end
    end
end

function Announcer:Reset()
    wipe(lastSpoken)
    wipe(drinkAnnounced)
    wipe(lowHpAnnounced)
    self:DebugPrint("reset (arena joined)")
end

function Announcer:DumpStatus()
    local cfg = AA.db.profile.announcer
    local _, instanceType = IsInInstance()
    addon:Print("--- Announcer status ---")
    addon:Print(("  build=%s version=%s debug=%s inArena=%s instanceType=%s"):format(
        tostring(self.build), tostring(AA.version), tostring(self.debug),
        tostring(AA.inArena), tostring(instanceType)))
    addon:Print(("  enabled=%s useSounds=%s useTTS=%s channel=%s"):format(
        tostring(cfg.enabled), tostring(cfg.useSounds ~= false),
        tostring(cfg.useTTS), tostring(cfg.channel or "Master")))
    addon:Print(("  casts=%s cooldowns=%s interrupts=%s trinket=%s drink=%s res=%s lowHP=%s"):format(
        tostring(cfg.casts), tostring(cfg.cooldowns), tostring(cfg.interrupts),
        tostring(cfg.trinket), tostring(cfg.drink), tostring(cfg.resurrect),
        tostring(cfg.lowHealth)))
    addon:Print(("  chatCallout=%s"):format(tostring(cfg.chatCallout or "off")))
    addon:Print(("  voicePath=%s"):format(VOICE_PATH))
    addon:Print("Test: /aa announcer test   (plays trinket.ogg)")
end

function Announcer:SetDebug(on)
    self.debug = not not on
    addon:Print(("Announcer debug %s."):format(self.debug and "ON" or "OFF"))
    if self.debug then
        self:DumpStatus()
    end
end

function Announcer:OnEnable()
    self.badVoices = {}
    self.ttsApi = "modern"
    -- Existing profiles still have useTTS=true from the old default; flip once
    -- to the voice-pack primary setup.
    local cfg = AA.db.profile.announcer
    if not cfg.voicePackV1 then
        cfg.useSounds = true
        cfg.useTTS = false
        if cfg.cooldowns == nil then cfg.cooldowns = true end
        cfg.voicePackV1 = true
    end
    self:RegisterMessage("AA_TRINKET_USED", "OnTrinketUsed")
    self:RegisterMessage("AA_CLEU", "OnCLEU")
    self:RegisterMessage("AA_ARENA_JOINED", "Reset")
    self:RegisterEvent("UNIT_SPELLCAST_START", "OnCastStart")
    self:RegisterEvent("UNIT_AURA", "OnUnitAura")
    self:RegisterEvent("UNIT_HEALTH", "OnUnitHealth")
    self:RegisterEvent("VOICE_CHAT_TTS_SPEAK_TEXT_UPDATE", "OnTtsUpdate")
end
