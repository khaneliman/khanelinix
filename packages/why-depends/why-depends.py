#!/usr/bin/env python3

import os
import subprocess
import sys


def run(cmd, capture_output=True, check=True, text=True):
    return subprocess.run(
        cmd, capture_output=capture_output, check=check, text=text
    ).stdout.strip()


def get_result_path():
    return os.path.realpath("result")


def resolve_host_to_flake_output(host_name):
    """Convert a host name to the appropriate flake output path."""
    # Just try both configurations and see which works
    nixos_path = f".#nixosConfigurations.{host_name}.config.system.build.toplevel"
    darwin_path = f".#darwinConfigurations.{host_name}.system"

    print(f"🎯 Trying to resolve host '{host_name}'...")

    # Return the first valid path, prioritizing nixOS
    return nixos_path, darwin_path


def nix_build(flake_output):
    print(f"🔨 Building {flake_output}...")
    try:
        subprocess.run(["nix", "build", flake_output], check=True)
        return True
    except subprocess.CalledProcessError:
        return False


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


def run_why_depends_derivation(flake_output, search_term):
    """Use derivation-based analysis - no building required!"""
    print(f"🔍 Searching for '{search_term}' in derivation dependencies...")

    # Try to find matching packages in nixpkgs that contain the search term
    # We'll search both the current flake and nixpkgs
    search_targets = [
        f"nixpkgs#{search_term}",  # Direct package
        f".#{search_term}",       # Local package
    ]

    found_target = None
    for target in search_targets:
        try:
            # Test if the target exists
            run(["nix", "eval", "--raw", target, "--apply", "toString"], check=True)
            found_target = target
            print(f"✅ Found target package: {target}")
            break
        except subprocess.CalledProcessError:
            continue

    if found_target:
        print("🔎 Running nix why-depends --derivation:\n")
        subprocess.run(["nix", "why-depends", "--derivation", flake_output, found_target])
    else:
        print(f"❌ Could not find a package matching '{search_term}'")
        print("💡 Try using the exact package name or search manually with:")
        print(f"   nix search nixpkgs {search_term}")
        print("   Then use: nix why-depends --derivation {flake_output} nixpkgs#<exact-package-name>")


def main():
    if len(sys.argv) < 3:
        print("Usage: why-depends [--fast] <host-name-or-flake-output> <partial-pname>")
        print()
        print("Examples:")
        print("  why-depends khanelinix chromium-unwrapped")
        print("  why-depends --fast khanelimac firefox")
        print("  why-depends .#nixosConfigurations.khanelinix.config.system.build.toplevel chromium-unwrapped")
        print()
        print("Options:")
        print("  --fast  Use derivation analysis (no building required)")
        print()
        print("💡 You can now use just the host name instead of the full flake path!")
        sys.exit(1)

    # Parse arguments
    args = sys.argv[1:]
    fast_mode = False

    if args[0] == "--fast":
        fast_mode = True
        args = args[1:]

    if len(args) != 2:
        print("Error: Need exactly 2 arguments after options")
        sys.exit(1)

    first_arg = args[0]
    search_term = args[1]

    # Determine if first argument is a host name or full flake output
    if first_arg.startswith(".#"):
        # Full flake output provided
        flake_output = first_arg
        print(f"🎯 Using provided flake output: {flake_output}")
    else:
        # Host name provided, resolve it
        nixos_path, darwin_path = resolve_host_to_flake_output(first_arg)

        if fast_mode:
            # In fast mode, try to determine which exists without building
            print("🔍 Fast mode: checking derivations...")
            try:
                run(["nix", "derivation", "show", nixos_path], check=True)
                flake_output = nixos_path
                print(f"✅ Found NixOS configuration: {flake_output}")
            except subprocess.CalledProcessError:
                try:
                    run(["nix", "derivation", "show", darwin_path], check=True)
                    flake_output = darwin_path
                    print(f"✅ Found Darwin configuration: {flake_output}")
                except subprocess.CalledProcessError:
                    print(f"❌ Host '{first_arg}' not found in either nixosConfigurations or darwinConfigurations.")
                    print("💡 Make sure the host name matches a configuration in your flake.")
                    print("   You can check available configurations with: nix flake show")
                    sys.exit(1)
        else:
            # Original behavior - try building
            print("🔍 Trying NixOS configuration...")
            if nix_build(nixos_path):
                flake_output = nixos_path
            else:
                print("🔍 Trying Darwin configuration...")
                if nix_build(darwin_path):
                    flake_output = darwin_path
                else:
                    print(
                        f"❌ Host '{first_arg}' not found in either nixosConfigurations or darwinConfigurations."
                    )
                    print(
                        "💡 Make sure the host name matches a configuration in your flake."
                    )
                    print("   You can check available configurations with: nix flake show")
                    sys.exit(1)

    if fast_mode:
        print("🚀 Using fast derivation analysis (no building required)")
        # Use derivation-based analysis
        run_why_depends_derivation(flake_output, search_term)
    else:
        # If we got here with a provided flake output, build it
        if first_arg.startswith(".#"):
            if not nix_build(flake_output):
                print(f"❌ Failed to build {flake_output}")
                sys.exit(1)

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
