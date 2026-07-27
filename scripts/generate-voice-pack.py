#!/usr/bin/env python3
"""Generate Arena Armory announcer clips with Google Cloud Text-to-Speech.

Uses a Neural2 voice at arena pace (speaking_rate), then encodes to .ogg.

Prereqs:
  pip install google-cloud-texttospeech
  gcloud auth application-default login
  gcloud services enable texttospeech.googleapis.com --project=YOUR_PROJECT

Usage:
  python scripts/generate-voice-pack.py
  python scripts/generate-voice-pack.py --rate 1.35 --voice en-US-Neural2-J
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

CLIPS = {
    "trinket": "Trinket",
    "blind": "Blind",
    "polymorph": "Polymorph",
    "fear": "Fear",
    "howl": "Howl of Terror",
    "cyclone": "Cyclone",
    "repentance": "Repentance",
    "wyvern": "Wyvern",
    "hibernate": "Hibernate",
    "roots": "Roots",
    "manaburn": "Mana Burn",
    "seduction": "Seduction",
    "psychicscream": "Psychic Scream",
    "hammer": "Hammer of Justice",
    "scatter": "Scatter",
    "freezingtrap": "Freezing Trap",
    "sap": "Sap",
    "gouge": "Gouge",
    "kidney": "Kidney Shot",
    "cheapshot": "Cheap Shot",
    "deathcoil": "Death Coil",
    "shadowfury": "Shadowfury",
    "intimidation": "Intimidating Shout",
    "silence": "Silence",
    "counterspell": "Counterspell",
    "kick": "Kick",
    "pummel": "Pummel",
    "spelllock": "Spell Lock",
    "bubble": "Bubble",
    "iceblock": "Ice Block",
    "cloak": "Cloak",
    "evasion": "Evasion",
    "vanish": "Vanish",
    "deterrence": "Deterrence",
    "bop": "Blessing of Protection",
    "painsuppression": "Pain Suppression",
    "natureswiftness": "Nature's Swiftness",
    "grounding": "Grounding",
    "spellreflection": "Spell Reflection",
    "coldblood": "Cold Blood",
    "adrenalinerush": "Adrenaline Rush",
    "bloodlust": "Bloodlust",
    "heroism": "Heroism",
    "innervate": "Innervate",
    "barkskin": "Barkskin",
    "presenceofmind": "Presence of Mind",
    "avengingwrath": "Avenging Wrath",
    "drinking": "Drinking",
    "resurrect": "Resurrect",
    "lowhealth": "Low health",
    # Expanded TBC arena callouts
    "freedom": "Freedom",
    "divineprotection": "Divine Protection",
    "layonhands": "Lay on Hands",
    "intercept": "Intercept",
    "charge": "Charge",
    "deathwish": "Death Wish",
    "recklessness": "Recklessness",
    "berserkerrage": "Berserker Rage",
    "readiness": "Readiness",
    "beastwithin": "Beast Within",
    "petintimidation": "Intimidation",
    "silencingshot": "Silencing Shot",
    "sprint": "Sprint",
    "preparation": "Preparation",
    "shadowstep": "Shadowstep",
    "premeditation": "Premeditation",
    "stealth": "Stealth",
    "powerinfusion": "Power Infusion",
    "fearward": "Fear Ward",
    "shadowfiend": "Shadowfiend",
    "elementalmastery": "Elemental Mastery",
    "shamanisticrage": "Shamanistic Rage",
    "tremor": "Tremor Totem",
    "manatide": "Mana Tide",
    "icyveins": "Icy Veins",
    "arcanepower": "Arcane Power",
    "combustion": "Combustion",
    "coldsnap": "Cold Snap",
    "blink": "Blink",
    "frostnova": "Frost Nova",
    "dragonsbreath": "Dragon's Breath",
    "spellsteal": "Spellsteal",
    "feldomination": "Fel Domination",
    "soulstone": "Soulstone",
    "bash": "Bash",
    "feralcharge": "Feral Charge",
    "wotf": "Will of the Forsaken",
    "warstomp": "War Stomp",
    "stoneform": "Stoneform",
    "escapeartist": "Escape Artist",
}


def find_ffmpeg() -> str:
    which = shutil.which("ffmpeg")
    if which:
        return which
    local = Path.home() / "AppData/Local/Microsoft/WinGet/Packages"
    matches = list(local.glob("Gyan.FFmpeg*/ffmpeg-*/bin/ffmpeg.exe"))
    if matches:
        return str(matches[0])
    raise SystemExit("ffmpeg not found. Install with: winget install Gyan.FFmpeg")


def synth_google(text: str, voice: str, rate: float, pitch: float) -> bytes:
    from google.cloud import texttospeech

    client = texttospeech.TextToSpeechClient()
    language = "-".join(voice.split("-")[:2])  # en-US-Neural2-J -> en-US
    input_text = texttospeech.SynthesisInput(text=text)
    voice_params = texttospeech.VoiceSelectionParams(
        language_code=language,
        name=voice,
    )
    audio_config = texttospeech.AudioConfig(
        audio_encoding=texttospeech.AudioEncoding.LINEAR16,
        speaking_rate=rate,
        pitch=pitch,
        sample_rate_hertz=24000,
    )
    response = client.synthesize_speech(
        input=input_text,
        voice=voice_params,
        audio_config=audio_config,
    )
    return response.audio_content


def wav_to_ogg(ffmpeg: str, wav_path: Path, ogg_path: Path) -> None:
    # Already spoken at arena rate by Cloud TTS; light loudnorm for punch.
    cmd = [
        ffmpeg,
        "-y",
        "-i",
        str(wav_path),
        "-af",
        "loudnorm=I=-14:TP=-1.5:LRA=11",
        "-c:a",
        "libvorbis",
        "-q:a",
        "5",
        str(ogg_path),
    ]
    subprocess.run(cmd, check=True, capture_output=True)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--voice",
        # Chirp3-HD female voices outrank Neural2 for clarity; Aoede is a
        # strong default for short arena callouts. Alternatives: Kore, Leda.
        default="en-US-Chirp3-HD-Aoede",
        help="Google Cloud voice name (Chirp3-HD female recommended)",
    )
    parser.add_argument(
        "--rate",
        type=float,
        default=1.35,
        help="speaking_rate for arena pace (1.0 = normal, 1.35 = snappy)",
    )
    parser.add_argument("--pitch", type=float, default=0.0)
    parser.add_argument(
        "--only",
        nargs="*",
        help="Optional subset of clip keys to regenerate",
    )
    args = parser.parse_args()

    root = Path(__file__).resolve().parent.parent
    out_dir = root / "ArenaArmory" / "Media" / "Voice"
    out_dir.mkdir(parents=True, exist_ok=True)
    ffmpeg = find_ffmpeg()

    clips = CLIPS
    if args.only:
        missing = [k for k in args.only if k not in CLIPS]
        if missing:
            raise SystemExit(f"Unknown clip keys: {missing}")
        clips = {k: CLIPS[k] for k in args.only}

    print(f"Voice: {args.voice}  rate={args.rate}  pitch={args.pitch}")
    print(f"Output: {out_dir}")

    try:
        # Probe credentials early with a tiny synth.
        synth_google("ok", args.voice, args.rate, args.pitch)
    except Exception as exc:  # noqa: BLE001 - surface setup errors clearly
        print("\nGoogle Cloud TTS failed. Fix auth, then re-run:\n", file=sys.stderr)
        print("  gcloud auth application-default login", file=sys.stderr)
        print(
            "  gcloud services enable texttospeech.googleapis.com --project=$(gcloud config get-value project)",
            file=sys.stderr,
        )
        print(f"\nError: {exc}", file=sys.stderr)
        return 1

    with tempfile.TemporaryDirectory(prefix="aa-voice-") as tmp:
        tmp_path = Path(tmp)
        for key, text in clips.items():
            print(f"  {key}.ogg <= \"{text}\"")
            audio = synth_google(text, args.voice, args.rate, args.pitch)
            wav_path = tmp_path / f"{key}.wav"
            ogg_path = out_dir / f"{key}.ogg"
            wav_path.write_bytes(audio)
            wav_to_ogg(ffmpeg, wav_path, ogg_path)

    print(f"Done: {len(clips)} clips")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
