-- Audio announcer (GladiatorlosSA-style) using built-in text-to-speech.
local _, AA = ...
local addon = AA.addon

local Announcer = addon:NewModule("Announcer", "AceEvent-3.0")
AA.Announcer = Announcer

local lastSpoken = {}      -- message -> last GetTime() (anti-spam)
local drinkAnnounced = {}  -- arena index -> true while drinking
local lowHpAnnounced = {}  -- arena index -> last announce time

local SPAM_WINDOW = 3

function AA.GetTtsVoices()
    if C_VoiceChat and C_VoiceChat.GetTtsVoices then
        return C_VoiceChat.GetTtsVoices() or {}
    end
    return {}
end

function AA.GetTtsVoiceCount()
    return #AA.GetTtsVoices()
end

-- Picks a voice: the user's Announcer choice, then a voice that already
-- worked this session, then WoW's Accessibility setting, then the first
-- installed voice. Only IDs present in the installed-voice list are used,
-- because the client silently plays nothing for invalid IDs.
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

function Announcer:SpeakWith(voiceID, msg)
    local dest = 1 -- LocalPlayback
    if Enum and Enum.VoiceTtsDestination then
        dest = Enum.VoiceTtsDestination.QueuedLocalPlayback
            or Enum.VoiceTtsDestination.LocalPlayback or 1
    end
    self.lastVoiceID = voiceID
    self.lastMsg = msg
    C_VoiceChat.SpeakText(voiceID, msg, dest, 0, 100)
end

-- The client reports per-utterance status asynchronously; some installed
-- voice IDs fail silently, so on failure we retry the message once per
-- remaining voice and remember whichever one actually works.
function Announcer:OnTtsUpdate(_, status)
    local ok = status == 0 or status == 6 or status == 9 -- Success / Enqueued / EnqueueNotNecessary
    if ok then
        self.workingVoiceID = self.lastVoiceID
        wipe(self.badVoices)
        return
    end

    local msg = self.lastMsg
    if not msg or not self.lastVoiceID then return end
    self.badVoices[self.lastVoiceID] = true
    self.lastMsg = nil

    for _, v in ipairs(AA.GetTtsVoices()) do
        if v.voiceID and not self.badVoices[v.voiceID] then
            self:SpeakWith(v.voiceID, msg)
            return
        end
    end
    addon:Print(("Text-to-speech failed on every installed voice (last status %d). Falling back to alert sound."):format(status))
    PlaySound(SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959, "Master")
end

function Announcer:Speak(msg, force)
    local cfg = AA.db.profile.announcer
    if not cfg.enabled then return end

    local now = GetTime()
    if not force and lastSpoken[msg] and (now - lastSpoken[msg]) < SPAM_WINDOW then return end
    lastSpoken[msg] = now

    local spoken = false
    if cfg.useTTS and C_VoiceChat and C_VoiceChat.SpeakText then
        local voiceID = self:ResolveVoiceID()
        if voiceID then
            self:SpeakWith(voiceID, msg)
            spoken = true
        end
    end
    if not spoken then
        PlaySound(SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959, "Master")
    end
    if RaidNotice_AddMessage and RaidWarningFrame then
        RaidNotice_AddMessage(RaidWarningFrame, msg, ChatTypeInfo["RAID_WARNING"])
    end
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

-------------------------------------------------------------------------------
-- Triggers
-------------------------------------------------------------------------------

function Announcer:OnTrinketUsed(_, i)
    if AA.testMode then return end -- test-mode refreshes would spam it
    if AA.db.profile.announcer.trinket then
        self:Speak(OpponentLabel(i) .. " trinket used", true)
    end
end

function Announcer:OnCastStart(_, unit, _, spellId)
    local i = AA.ArenaIndex(unit)
    if not i then return end
    local cfg = AA.db.profile.announcer

    local label = spellId and AA.ANNOUNCE_CASTS[spellId]
    if label and cfg.casts then
        self:Speak(label)
        return
    end
    local resLabel = spellId and AA.ANNOUNCE_RES[spellId]
    if resLabel and cfg.resurrect then
        self:Speak("Resurrecting", true)
    end
end

function Announcer:OnCLEU(_, _, subevent, sourceGUID, _, _, _, _, _, spellId)
    if subevent ~= "SPELL_CAST_SUCCESS" then return end
    if not AA.db.profile.announcer.casts then return end
    local unit = AA.UnitByGUID(sourceGUID)
    if not unit then return end

    -- Instants (Blind, Psychic Scream, ...) never fire UNIT_SPELLCAST_START.
    local label = spellId and AA.ANNOUNCE_CASTS[spellId]
    if label then
        self:Speak(label)
    end
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
        self:Speak(OpponentLabel(i) .. " drinking")
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
            self:Speak(OpponentLabel(i) .. " low health")
        end
    end
end

function Announcer:Reset()
    wipe(lastSpoken)
    wipe(drinkAnnounced)
    wipe(lowHpAnnounced)
end

function Announcer:OnEnable()
    self.badVoices = {}
    self:RegisterMessage("AA_TRINKET_USED", "OnTrinketUsed")
    self:RegisterMessage("AA_CLEU", "OnCLEU")
    self:RegisterMessage("AA_ARENA_JOINED", "Reset")
    self:RegisterEvent("UNIT_SPELLCAST_START", "OnCastStart")
    self:RegisterEvent("UNIT_AURA", "OnUnitAura")
    self:RegisterEvent("UNIT_HEALTH", "OnUnitHealth")
    self:RegisterEvent("VOICE_CHAT_TTS_SPEAK_TEXT_UPDATE", "OnTtsUpdate")
end
