#! /usr/bin/env python3

"""
Audio Stream Fixer for Video Files
==================================

This script scans video files (MKV, MP4, AVI, M4V) to ensure the default audio
track is set to English.

Logic:
  1. Checks if the current default audio stream is English.
  2. Checks if the current default is in the "Ignore List" (e.g., Japanese for Anime).
  3. If NOT English and NOT Ignored, it searches for a "hidden" English stream.
  4. If found, the file is marked [FIXABLE].
  5. With the --fix flag, it swaps the default disposition flags using:
     - mkvpropedit (Instant, MKV only)
     - ffmpeg (Slow copy, fallback for MP4/AVI)

Usage:
  audio-stream-fixer [TARGET] [OPTIONS]

Examples:
  # 1. Scan a directory (Dry Run - No changes)
  audio-stream-fixer /mnt/media/movies

  # 2. Fix a specific file
  audio-stream-fixer /mnt/media/movies/Avatar.mkv --fix

  # 3. Batch fix, but ignore Anime (skip if default is already Japanese)
  audio-stream-fixer /mnt/media/movies --fix --ignore-langs jpn,kor

  # 4. Interactive Mode (Ask before fixing each file)
  audio-stream-fixer /mnt/media/movies --fix --interactive

  # 5. Output fixable list to JSON (for external scripts/CI)
  audio-stream-fixer /mnt/media/movies --output-file results.json

Dependencies:
  - python3
  - ffmpeg (ffprobe)
  - mkvtoolnix (mkvpropedit) - ESSENTIAL for fast fixes
"""

import argparse
import json
import os
import shutil
import subprocess
import sys

# Extensions to scan
EXTENSIONS = {".mkv", ".mp4", ".avi", ".m4v"}


def check_dependencies():
    if not shutil.which("ffprobe"):
        print("Error: 'ffprobe' missing.")
        sys.exit(1)
    if not shutil.which("mkvpropedit"):
        print("Warning: 'mkvpropedit' not found. Fixes will be SLOW (ffmpeg copy).")


def analyze_file(filepath, ignore_langs):
    if os.path.splitext(filepath)[1].lower() not in EXTENSIONS:
        return {"status": "ignore"}

    try:
        cmd = [
            "ffprobe",
            "-v",
            "quiet",
            "-print_format",
            "json",
            "-show_streams",
            filepath,
        ]
        result = subprocess.run(cmd, capture_output=True, text=True)

        if not result.stdout:
            return {"status": "error", "msg": "no output"}

        data = json.loads(result.stdout)
        if not data.get("streams"):
            return {"status": "no_audio"}

        streams = data["streams"]

        audio_streams = []
        audio_counter = 0
        for s in streams:
            if s.get("codec_type") == "audio":
                audio_counter += 1
                s["mkv_number"] = audio_counter
                audio_streams.append(s)

        if not audio_streams:
            return {"status": "no_audio"}

        default_stream = next(
            (s for s in audio_streams if s.get("disposition", {}).get("default") == 1),
            None,
        )

        if not default_stream:
            default_stream = audio_streams[0]

        def_lang = default_stream.get("tags", {}).get("language", "und").lower()
        def_abs_index = default_stream.get("index")
        def_mkv_num = default_stream.get("mkv_number")

        if def_lang in ["eng", "en"]:
            return {"status": "ok"}

        if def_lang in ignore_langs:
            return {"status": "foreign_ok", "current_lang": def_lang}

        eng_candidate = next(
            (
                s
                for s in audio_streams
                if s.get("tags", {}).get("language", "").lower() in ["eng", "en"]
            ),
            None,
        )

        if eng_candidate:
            return {
                "status": "fixable",
                "current_lang": def_lang,
                "current_index": def_abs_index,
                "current_mkv": def_mkv_num,
                "eng_index": eng_candidate.get("index"),
                "eng_mkv": eng_candidate.get("mkv_number"),
                "path": filepath,
            }
        else:
            return {
                "status": "undef" if def_lang == "und" else "no_eng",
                "current_lang": def_lang,
            }

    except Exception as e:
        return {"status": "error", "msg": str(e)}


def apply_fix(item):
    filepath = item["path"]
    good_mkv = item["eng_mkv"]
    bad_mkv = item["current_mkv"]
    good_idx = item["eng_index"]
    bad_idx = item["current_index"]

    # --- STRATEGY 1: FAST (mkvpropedit) ---
    if filepath.endswith(".mkv") and shutil.which("mkvpropedit"):
        try:
            cmd = [
                "mkvpropedit",
                filepath,
                "--edit",
                f"track:a{good_mkv}",
                "--set",
                "flag-default=1",
                "--edit",
                f"track:a{bad_mkv}",
                "--set",
                "flag-default=0",
            ]
            subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL)
            print("      \033[92m[FIXED]\033[0m Instant (mkvpropedit)")
            return True
        except subprocess.CalledProcessError as e:
            print(f"      \033[91m[FAIL]\033[0m mkvpropedit error: {e}")

    # --- STRATEGY 2: SLOW (FFmpeg) ---
    print("      \033[93m[BUSY]\033[0m Running FFmpeg copy (Slow)...")
    temp_file = filepath + ".tmp" + os.path.splitext(filepath)[1]

    try:
        cmd = [
            "ffmpeg",
            "-v",
            "error",
            "-y",
            "-i",
            filepath,
            "-map",
            "0",
            "-c",
            "copy",
            f"-disposition:{good_idx}",
            "default",
            f"-disposition:{bad_idx}",
            "0",
            temp_file,
        ]
        subprocess.run(cmd, check=True)
        os.replace(temp_file, filepath)
        print("      \033[92m[FIXED]\033[0m FFmpeg copy complete.")
        return True
    except Exception as e:
        print(f"      \033[91m[FAIL]\033[0m FFmpeg error: {e}")
        if os.path.exists(temp_file):
            os.remove(temp_file)
        return False


def print_status_line(result, file_name, full_path):
    status = result.get("status")

    if status == "ok":
        return  # Don't spam OK files

    # Format columns
    if status == "fixable":
        curr = result["current_lang"]
        print(
            f"\033[96m[FIXABLE]\033[0m   {'Swappable (' + curr + '->eng)':<25} {file_name:<30} {full_path}"
        )
    elif status == "foreign_ok":
        curr = result["current_lang"]
        print(
            f"\033[92m[FOREIGN]\033[0m   {'Ignored (' + curr + ')':<25} {file_name:<30} {full_path}"
        )
    elif status == "no_eng":
        curr = result["current_lang"]
        print(
            f"\033[91m[NO ENG]\033[0m    {'Only found: ' + curr:<25} {file_name:<30} {full_path}"
        )
    elif status == "undef":
        print(f"\033[93m[?] UNDEF\033[0m   {'(und)':<25} {file_name:<30} {full_path}")
    elif status == "error":
        msg = result.get("msg")[:25]
        print(f"\033[91m[ERROR]\033[0m     {msg:<25} {file_name:<30} {full_path}")


def process_path(target_path, args, counts, results_list):
    """
    Handles file discovery AND immediate action.
    """

    # Generator to yield files one by one
    def file_generator(path):
        if os.path.isfile(path):
            yield path
        elif os.path.isdir(path):
            for root, _, files in os.walk(path):
                for file in files:
                    if "-trailer" not in file.lower():
                        yield os.path.join(root, file)

    for full_path in file_generator(target_path):
        result = analyze_file(full_path, args.ignore_langs)

        # Track stats
        status = result.get("status")
        if status in counts:
            counts[status] += 1

        # Print Status
        print_status_line(result, os.path.basename(full_path), full_path)

        # Handle FIXABLE items
        if status == "fixable":
            results_list.append(result)  # Save for JSON output

            if args.fix:
                should_fix = True

                # Interactive Prompt
                if args.interactive:
                    try:
                        # Print a distinct prompt line
                        user_input = input(
                            "      \033[95m[ACTION]\033[0m Fix this file? [y/N/q] "
                        ).lower()
                        if user_input == "q":
                            print("\n[INFO] Quitting...")
                            sys.exit(0)
                        if user_input != "y":
                            should_fix = False
                            print("      [SKIP] Skipped.")
                    except KeyboardInterrupt:
                        sys.exit(0)

                if should_fix:
                    apply_fix(result)


def main():
    check_dependencies()
    parser = argparse.ArgumentParser(description="Scan and Fix video audio streams.")
    parser.add_argument("target", help="The file OR directory to scan")
    parser.add_argument("--fix", action="store_true", help="Apply fixes immediately")
    parser.add_argument("--output-file", help="Dump fixable items to a JSON file")
    parser.add_argument(
        "--interactive", action="store_true", help="Ask for confirmation before fixing"
    )
    parser.add_argument(
        "--ignore-langs",
        help="Comma-separated list of languages to ignore (e.g. 'jpn,kor')",
    )

    args = parser.parse_args()

    # Process ignore list
    if args.ignore_langs:
        args.ignore_langs = [
            lang.strip().lower() for lang in args.ignore_langs.split(",")
        ]
    else:
        args.ignore_langs = []

    print(f"Scanning: {args.target}")
    print(f"{'STATUS':<12} {'DETAILS':<25} {'FILENAME':<30} {'FULL PATH'}")
    print("-" * 120)

    counts = {
        "fixable": 0,
        "no_eng": 0,
        "undef": 0,
        "ok": 0,
        "error": 0,
        "foreign_ok": 0,
    }
    fixable_items = []

    try:
        process_path(args.target, args, counts, fixable_items)
    except KeyboardInterrupt:
        print("\n[INFO] Scan interrupted.")

    print("-" * 120)
    print(
        f"Summary: {counts['fixable']} Fixable, {counts['foreign_ok']} Ignored, {counts['no_eng']} No English"
    )

    if args.output_file:
        try:
            with open(args.output_file, "w") as f:
                json.dump(fixable_items, f, indent=2)
            print(f"\n[INFO] Fixable list written to: {args.output_file}")
        except Exception as e:
            print(f"\n[ERROR] Could not write file: {e}")


if __name__ == "__main__":
    main()
