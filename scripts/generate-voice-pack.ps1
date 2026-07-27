# Legacy wrapper — prefer the Google Cloud Neural/Chirp generator:
#   python scripts/generate-voice-pack.py --voice en-US-Chirp3-HD-Aoede --rate 1.35
#
# This PowerShell path uses Windows SAPI (lower quality) and is kept only as a
# fallback when Cloud TTS is unavailable.
# Usage: powershell -File scripts\generate-voice-pack.ps1

$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $false
$outDir = Join-Path $PSScriptRoot "..\ArenaArmory\Media\Voice"
$tmpDir = Join-Path $env:TEMP "aa-voice-gen"
New-Item -ItemType Directory -Force -Path $outDir, $tmpDir | Out-Null

$ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
if (-not $ffmpeg) {
    $ffmpeg = Get-ChildItem -Path "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Filter ffmpeg.exe -Recurse -ErrorAction SilentlyContinue |
        Select-Object -First 1
}
if (-not $ffmpeg) { throw "ffmpeg not found. Install Gyan.FFmpeg via winget." }
$ffmpegPath = if ($ffmpeg.Source) { $ffmpeg.Source } else { $ffmpeg.FullName }

Add-Type -AssemblyName System.Speech
$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
$synth.Rate = 1
$synth.Volume = 100

# Prefer a clear English voice when available.
foreach ($v in $synth.GetInstalledVoices()) {
    $info = $v.VoiceInfo
    if ($info.Culture.Name -like "en-*" -and $info.Gender -eq "Female") {
        $synth.SelectVoice($info.Name)
        break
    }
}

$clips = [ordered]@{
    trinket           = "Trinket"
    blind             = "Blind"
    polymorph         = "Polymorph"
    fear              = "Fear"
    howl              = "Howl of Terror"
    cyclone           = "Cyclone"
    repentance        = "Repentance"
    wyvern            = "Wyvern"
    hibernate         = "Hibernate"
    roots             = "Roots"
    manaburn          = "Mana Burn"
    seduction         = "Seduction"
    psychicscream     = "Psychic Scream"
    hammer            = "Hammer of Justice"
    scatter           = "Scatter"
    freezingtrap      = "Freezing Trap"
    sap               = "Sap"
    gouge             = "Gouge"
    kidney            = "Kidney Shot"
    cheapshot         = "Cheap Shot"
    deathcoil         = "Death Coil"
    shadowfury        = "Shadowfury"
    intimidation      = "Intimidating Shout"
    silence           = "Silence"
    counterspell      = "Counterspell"
    kick              = "Kick"
    pummel            = "Pummel"
    spelllock         = "Spell Lock"
    bubble            = "Bubble"
    iceblock          = "Ice Block"
    cloak             = "Cloak"
    evasion           = "Evasion"
    vanish            = "Vanish"
    deterrence        = "Deterrence"
    bop               = "Hand of Protection"
    painsuppression   = "Pain Suppression"
    natureswiftness   = "Nature's Swiftness"
    grounding         = "Grounding"
    spellreflection   = "Spell Reflection"
    coldblood         = "Cold Blood"
    adrenalinerush    = "Adrenaline Rush"
    bloodlust         = "Bloodlust"
    heroism           = "Heroism"
    innervate         = "Innervate"
    barkskin          = "Barkskin"
    presenceofmind    = "Presence of Mind"
    avengingwrath     = "Avenging Wrath"
    drinking          = "Drinking"
    resurrect         = "Resurrect"
    lowhealth         = "Low health"
}

Write-Host "Voice: $($synth.Voice.Name)"
foreach ($entry in $clips.GetEnumerator()) {
    $key = $entry.Key
    $text = $entry.Value
    $wav = Join-Path $tmpDir "$key.wav"
    $ogg = Join-Path $outDir "$key.ogg"
    Write-Host "  $key.ogg <= `"$text`""
    $synth.SetOutputToWaveFile($wav)
    $synth.Speak($text)
    $synth.SetOutputToNull()
    $ffArgs = @("-y", "-i", $wav, "-c:a", "libvorbis", "-q:a", "4", $ogg)
    $p = Start-Process -FilePath $ffmpegPath -ArgumentList $ffArgs -Wait -PassThru -NoNewWindow `
        -RedirectStandardError (Join-Path $tmpDir "ffmpeg-$key.log")
    if ($p.ExitCode -ne 0) { throw "ffmpeg failed for $key (exit $($p.ExitCode))" }
}
$synth.Dispose()
Write-Host "Done: $outDir ($($clips.Count) clips)"
