#! /usr/bin/env python3

"""
Auto Language Tagger using OpenAI Whisper
=========================================
Detects the language of 'UNDEF' audio tracks and updates metadata.

Usage:
  python3 auto_tag_language.py /path/to/movies [OPTIONS]

Options:
  --apply         Apply the changes (default is Dry Run)
  --interactive   Ask for confirmation before applying each change
  --confidence    Minimum probability to apply change (default: 0.85)
  --model         Whisper model size (tiny, base, small, medium). 'base' is recommended.

Examples:
  # Dry run - scan and detect languages without applying changes
  auto-language-tagger /mnt/media/movies

  # Apply changes automatically when confidence >= 85%
  auto-language-tagger /mnt/media/movies --apply

  # Interactive mode - confirm each change
  auto-language-tagger /mnt/media/movies --apply --interactive

  # Use larger model (medium) with higher confidence threshold
  auto-language-tagger /mnt/media/movies --apply --model medium --confidence 0.9
"""

import argparse
import json
import os
import shutil
import subprocess
import sys
import warnings

# Suppress Whisper warnings
warnings.filterwarnings("ignore")

try:
    import whisper
except ImportError:
    print("Error: 'openai-whisper' not installed. Please enter your nix-shell.")
    sys.exit(1)

# Extensions to scan
EXTENSIONS = {".mkv", ".mp4", ".avi", ".m4v"}


def check_dependencies():
    if not shutil.which("ffmpeg"):
        print("Error: 'ffmpeg' missing.")
        sys.exit(1)
    if not shutil.which("mkvpropedit"):
        print(
            "Warning: 'mkvpropedit' not found. Only MKV metadata updates supported efficiently."
        )


def get_undef_audio_files(target_path):
    """
    Finds all files that have at least one UNDEF audio track.
    Returns list of dicts: {'path': str, 'track_index': int, 'mkv_number': int}
    """
    candidates = []

    # Generator for file walking
    def file_walker():
        if os.path.isfile(target_path):
            yield target_path
        else:
            for root, _, files in os.walk(target_path):
                for file in files:
                    if (
                        "-trailer" not in file.lower()
                        and os.path.splitext(file)[1].lower() in EXTENSIONS
                    ):
                        yield os.path.join(root, file)

    print("Scanning for UNDEF tracks...")

    file_count = 0
    try:
        for filepath in file_walker():
            file_count += 1
            if file_count % 10 == 0:
                print(
                    f"  Scanned {file_count} files, found {len(candidates)} UNDEF tracks so far...",
                    end="\r",
                )

            try:
                cmd = [
                    "ffprobe",
                    "-v",
                    "quiet",
                    "-print_format",
                    "json",
                    "-show_streams",
                    "-select_streams",
                    "a",
                    filepath,
                ]
                result = subprocess.run(cmd, capture_output=True, text=True)
                if not result.stdout:
                    continue

                data = json.loads(result.stdout)
                if not data.get("streams"):
                    continue

                # Check audio tracks
                mkv_counter = 0
                for s in data["streams"]:
                    mkv_counter += 1
                    lang = s.get("tags", {}).get("language", "und").lower()

                    # If language is undefined, it's a candidate
                    if lang == "und":
                        candidates.append(
                            {
                                "path": filepath,
                                "index": s["index"],  # FFmpeg absolute index
                                "mkv_num": mkv_counter,  # mkvpropedit 1-based index
                            }
                        )
                        # We process one UNDEF track per file to avoid complexity for now,
                        # or break here if you only want to fix the *first* undef track.
                        # Let's collect them all.
            except Exception:
                continue
    except KeyboardInterrupt:
        print(
            f"\n[INFO] Scan interrupted after {file_count} files. Found {len(candidates)} UNDEF tracks."
        )
        return candidates

    print()  # Clear the progress line
    return candidates


def extract_sample_audio(filepath, stream_index, output_wav):
    """
    Extracts 30 seconds of audio starting at 10 minutes (600s).
    If file is shorter than 10m, starts at 20% duration.
    """
    start_time = "600"  # Default 10 minutes in

    # Get duration to be safe
    try:
        cmd_dur = [
            "ffprobe",
            "-v",
            "error",
            "-show_entries",
            "format=duration",
            "-of",
            "default=noprint_wrappers=1:nokey=1",
            filepath,
        ]
        dur = float(subprocess.check_output(cmd_dur).decode().strip())
        if dur < 1200:  # If movie is < 20 mins
            start_time = str(int(dur * 0.2))  # Start at 20%
    except Exception:
        pass

    # Extract mono 16khz wav (ideal for whisper)
    cmd = [
        "ffmpeg",
        "-v",
        "error",
        "-y",
        "-ss",
        start_time,
        "-t",
        "30",  # 30 seconds
        "-i",
        filepath,
        "-map",
        f"0:{stream_index}",  # Specific stream
        "-ac",
        "1",
        "-ar",
        "16000",  # Mono 16k
        output_wav,
    ]
    subprocess.run(cmd, stdout=subprocess.DEVNULL)


def detect_language(model, audio_path):
    """
    Returns (language_code, probability)
    e.g. ('en', 0.98)
    """
    # Load audio
    audio = whisper.load_audio(audio_path)
    audio = whisper.pad_or_trim(audio)

    # Make log-Mel spectrogram
    mel = whisper.log_mel_spectrogram(audio).to(model.device)

    # Detect
    _, probs = model.detect_language(mel)
    detected_lang = max(probs, key=probs.get)
    confidence = probs[detected_lang]

    return detected_lang, confidence


def update_metadata(filepath, mkv_num, lang_code):
    """
    Uses mkvpropedit to set language.
    """
    if not filepath.endswith(".mkv"):
        print(f"      [SKIP] Cannot update non-MKV metadata instantly: {filepath}")
        return False

    try:
        cmd = [
            "mkvpropedit",
            filepath,
            "--edit",
            f"track:a{mkv_num}",
            "--set",
            f"language={lang_code}",
        ]
        subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL)
        return True
    except subprocess.CalledProcessError as e:
        print(f"      [ERROR] mkvpropedit failed: {e}")
        return False


def main():
    parser = argparse.ArgumentParser(
        description="Auto-detect languages for UNDEF audio tracks."
    )
    parser.add_argument("target", help="Directory or file to scan")
    parser.add_argument(
        "--apply", action="store_true", help="Apply changes to metadata"
    )
    parser.add_argument(
        "--interactive",
        action="store_true",
        help="Ask for confirmation before applying each change",
    )
    parser.add_argument(
        "--confidence", type=float, default=0.85, help="Confidence threshold (0.0-1.0)"
    )
    parser.add_argument(
        "--model", default="base", help="Whisper model: tiny, base, small, medium"
    )

    args = parser.parse_args()
    check_dependencies()

    # 1. Load Model
    print(f"Loading Whisper model '{args.model}'...")
    try:
        model = whisper.load_model(args.model)
    except Exception as e:
        print(f"Failed to load model: {e}")
        sys.exit(1)

    # 2. Find Candidates
    candidates = get_undef_audio_files(args.target)
    print(f"Found {len(candidates)} UNDEF audio tracks to analyze.")
    print("-" * 80)

    temp_wav = "temp_whisper_sample.wav"

    try:
        for item in candidates:
            filename = os.path.basename(item["path"])
            print(f"Analyzing: {filename} (Track #{item['mkv_num']})")

            # Extract
            extract_sample_audio(item["path"], item["index"], temp_wav)

            if not os.path.exists(temp_wav):
                print("      [ERROR] Audio extraction failed.")
                continue

            # Detect
            lang, prob = detect_language(model, temp_wav)

            # Output Result
            conf_str = f"{prob * 100:.1f}%"
            if prob >= args.confidence:
                color = "\033[92m"  # Green
                status = f"DETECTED: {lang} ({conf_str})"
            else:
                color = "\033[93m"  # Yellow
                status = f"UNCERTAIN: {lang} ({conf_str})"

            print(f"      {color}[{status}]\033[0m")

            # Apply
            if args.apply and prob >= args.confidence:
                should_apply = True

                # Interactive confirmation
                if args.interactive:
                    try:
                        user_input = input(
                            f"      \033[95m[ACTION]\033[0m Apply language tag '{lang}'? [y/N/q] "
                        ).lower()
                        if user_input == "q":
                            print("\n[INFO] Quitting...")
                            break
                        if user_input != "y":
                            should_apply = False
                            print("      [SKIP] Skipped.")
                    except KeyboardInterrupt:
                        print("\n[INFO] Analysis interrupted by user.")
                        break

                if should_apply:
                    # Convert 2-letter Whisper code to 3-letter ISO code if needed by mkvpropedit?
                    # Actually mkvpropedit accepts 'en', 'ja', 'fr' usually.
                    # Strict ISO 639-2 (3-letter) is better ('eng', 'jpn').
                    # Simple mapping for common ones:
                    iso_map = {
                        "en": "eng",
                        "ja": "jpn",
                        "fr": "fre",
                        "de": "ger",
                        "es": "spa",
                        "it": "ita",
                        "ko": "kor",
                        "zh": "chi",
                    }
                    final_lang = iso_map.get(lang, lang)

                    print(f"      Running mkvpropedit (language={final_lang})...")
                    update_metadata(item["path"], item["mkv_num"], final_lang)

    except KeyboardInterrupt:
        print("\n[INFO] Analysis interrupted by user.")
    finally:
        # Cleanup
        if os.path.exists(temp_wav):
            os.remove(temp_wav)


if __name__ == "__main__":
    main()
