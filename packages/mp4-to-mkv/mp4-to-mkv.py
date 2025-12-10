#! /usr/bin/env python3

"""
MP4 to MKV Converter
====================
Batch convert MP4/M4V files to MKV format using lossless remuxing (no re-encoding).

Usage:
  mp4-to-mkv /path/to/directory [OPTIONS]

Options:
  --delete    Delete source file after successful conversion

Examples:
  # Dry run - convert without deleting originals
  mp4-to-mkv /mnt/media/movies

  # Convert and delete originals after successful conversion
  mp4-to-mkv /mnt/media/movies --delete

Features:
  - Lossless conversion (no re-encoding, just remuxing)
  - Preserves all streams (video, audio, subtitles, chapters)
  - Skips files where MKV already exists
  - Safety checks before deleting source files
  - Recursive directory scanning
"""

import argparse
import os
import subprocess
import sys

# Extensions to target
TARGET_EXTS = {".mp4", ".m4v"}


def convert_to_mkv(filepath, delete_source=False, interactive=False):
    filename = os.path.basename(filepath)
    output_path = os.path.splitext(filepath)[0] + ".mkv"

    # Check if MKV already exists
    if os.path.exists(output_path):
        src_size = os.path.getsize(filepath)
        dst_size = os.path.getsize(output_path)

        if dst_size > (src_size * 0.9):
            print(f"[SKIP] MKV exists: {filename}")
            return
        else:
            print(f"[WARN] Partial MKV found. Overwriting: {filename}")

    # --- INTERACTIVE CHECK ---
    if interactive:
        try:
            user_input = input(f"\nConvert '{filename}'? [y/N/q] ").lower()
            if user_input == "q":
                print("Quitting...")
                sys.exit(0)
            if user_input != "y":
                print("[SKIP] User skipped.")
                return
        except KeyboardInterrupt:
            print("\nInterrupted.")
            sys.exit(0)

    print(f"[CONVERTING] {filename}...")

    try:
        # -map 0 copies ALL streams (video, audio, subs, chapters)
        # -c copy does strictly no re-encoding (Lossless)
        # -y allows overwrite (we already checked for existing files above)
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
            output_path,
        ]

        # Run ffmpeg with no stdin to avoid conflicts with interactive mode
        subprocess.run(cmd, check=True, stdin=subprocess.DEVNULL)
        print("   \033[92m[DONE]\033[0m Created MKV")

        # --- DELETE LOGIC ---
        if delete_source:
            # Double check MKV exists and has size
            if os.path.exists(output_path) and os.path.getsize(output_path) > 100:
                # If interactive, ask specifically about deletion?
                # Or assume "Convert [y]" implied "Convert and Delete [y]"?
                # Usually safer to just do it if the flag was passed,
                # but let's double check if we are in interactive mode.

                if interactive:
                    confirm_del = input(
                        "   \033[93m[CONFIRM]\033[0m Delete original MP4? [y/N] "
                    ).lower()
                    if confirm_del != "y":
                        print("   [KEEP] Original file kept.")
                        return

                os.remove(filepath)
                print("   \033[93m[DEL]\033[0m Deleted original MP4")
            else:
                print("   \033[91m[ERR]\033[0m Output missing/empty. Keeping source.")

    except subprocess.CalledProcessError:
        print("   \033[91m[FAIL]\033[0m Conversion failed")
        if os.path.exists(output_path):
            os.remove(output_path)
    except Exception as e:
        print(f"   \033[91m[ERR]\033[0m {e}")


def main():
    parser = argparse.ArgumentParser(
        description="Batch Convert MP4/M4V to MKV (Lossless)"
    )
    parser.add_argument("directory", help="Directory to scan")
    parser.add_argument(
        "--delete",
        action="store_true",
        help="Delete source file after successful conversion",
    )
    parser.add_argument(
        "--interactive", action="store_true", help="Ask confirmation for every file"
    )

    args = parser.parse_args()

    if not os.path.isdir(args.directory):
        print("Error: Target is not a directory.")
        sys.exit(1)

    print(f"Scanning {args.directory} for MP4 files...")
    count = 0

    for root, _, files in os.walk(args.directory):
        for file in files:
            if os.path.splitext(file)[1].lower() in TARGET_EXTS:
                full_path = os.path.join(root, file)
                convert_to_mkv(full_path, args.delete, args.interactive)
                count += 1

    print("-" * 40)
    print(f"Processed {count} files.")


if __name__ == "__main__":
    main()
