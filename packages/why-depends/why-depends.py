#!/usr/bin/env python3

import os
import subprocess
import sys


def run(cmd, capture_output=True, check=True, text=True):
    return subprocess.run(cmd, capture_output=capture_output, check=check, text=text).stdout.strip()

def get_result_path():
    return os.path.realpath("result")

def nix_build(flake_output):
    print(f"🔨 Building {flake_output}...")
    subprocess.run(["nix", "build", flake_output], check=True)

def find_matches(closure_path, search_term):
    print(f"🔍 Searching for dependency matching '{search_term}'...")
    refs = run(["nix-store", "-qR", closure_path]).splitlines()
    matches = [ref for ref in refs if search_term in ref]
    return matches

def pick_match(matches):
    if len(matches) == 1:
        return matches[0]
    print("\n⚠️  Multiple matches found. Please select one:")
    for idx, match in enumerate(matches, 1):
        print(f"{idx}) {match}")
    while True:
        try:
            choice = int(input("#? "))
            if 1 <= choice <= len(matches):
                return matches[choice - 1]
        except ValueError:
            pass
        print("Invalid choice. Try again.")

def run_why_depends(toplevel_path, dep_path):
    print("🔎 Running nix why-depends:\n")
    subprocess.run(["nix", "why-depends", toplevel_path, dep_path])

def main():
    if len(sys.argv) != 3:
        print("Usage: why_depends.py <flake-output> <partial-pname>")
        print("Example: why_depends.py .#nixosConfigurations.khanelinix.config.system.build.toplevel chromium-unwrapped")
        sys.exit(1)

    flake_output = sys.argv[1]
    search_term = sys.argv[2]

    nix_build(flake_output)
    toplevel_path = get_result_path()
    print(f"📦 Toplevel path: {toplevel_path}")

    matches = find_matches(toplevel_path, search_term)
    if not matches:
        print(f"❌ No match found for '{search_term}' in the closure.")
        sys.exit(1)

    print("✅ Found match(es):")
    for m in matches:
        print(m)

    dep_path = pick_match(matches)
    run_why_depends(toplevel_path, dep_path)

if __name__ == "__main__":
    main()
