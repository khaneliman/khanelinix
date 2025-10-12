#!/usr/bin/env python3

import json
import os
import subprocess
import sys


def run(cmd, capture_output=True, check=True, text=True):
    return subprocess.run(
        cmd, capture_output=capture_output, check=check, text=text
    ).stdout.strip()


def run_safe(cmd, capture_output=True, text=True):
    """Run command and return (success, stdout, stderr)"""
    try:
        result = subprocess.run(
            cmd, capture_output=capture_output, text=text, check=False
        )
        return result.returncode == 0, result.stdout.strip(), result.stderr.strip()
    except Exception as e:
        return False, "", str(e)


def get_result_path():
    return os.path.realpath("result")


def resolve_host_to_flake_output(host_name):
    """Convert a host name to the appropriate flake output path."""
    nixos_path = f".#nixosConfigurations.{host_name}.config.system.build.toplevel"
    darwin_path = f".#darwinConfigurations.{host_name}.system"

    print(f"🎯 Trying to resolve host '{host_name}'...")
    return nixos_path, darwin_path


def check_config_exists_fast(flake_output):
    """Fast check if configuration exists using derivation show"""
    success, stdout, stderr = run_safe(["nix", "derivation", "show", flake_output])
    if success:
        return True, "exists"

    # Parse error to give better feedback
    if "does not provide attribute" in stderr:
        if "nixosConfigurations" in flake_output:
            return False, "not_in_nixos"
        elif "darwinConfigurations" in flake_output:
            return False, "not_in_darwin"

    return False, "unknown_error"


def nix_build_safe(flake_output):
    """Build with better error classification"""
    print(f"🔨 Building {flake_output}...")
    success, stdout, stderr = run_safe(["nix", "build", flake_output])

    if success:
        return True, "success"

    # Classify the error
    if "does not provide attribute" in stderr:
        if "nixosConfigurations" in flake_output:
            return False, "not_in_nixos"
        elif "darwinConfigurations" in flake_output:
            return False, "not_in_darwin"
        return False, "config_not_found"
    elif "Cannot build" in stderr or "builder failed" in stderr:
        return False, "build_failed"
    else:
        return False, "unknown_error"


def find_matches(closure_path, search_term):
    print(f"🔍 Searching for dependency matching '{search_term}'...")
    refs = run(["nix-store", "-qR", closure_path]).splitlines()
    matches = [ref for ref in refs if search_term in ref]
    return matches


def find_package_in_derivation(flake_output, search_term):
    """Search for packages in the derivation graph that match the search term"""
    print(f"🔍 Searching for '{search_term}' in derivation dependencies...")

    # Get the derivation info
    success, stdout, stderr = run_safe(
        ["nix", "derivation", "show", "-r", flake_output]
    )
    if not success:
        print(f"❌ Failed to get derivation info: {stderr}")
        return []

    try:
        derivation_data = json.loads(stdout)
        matches = []

        # Search through all derivations recursively
        for drv_path, drv_info in derivation_data.items():
            # Check the derivation path itself
            if search_term in drv_path:
                matches.append(drv_path)

            # Check the package name in the derivation
            name = drv_info.get("name", "")
            if search_term in name:
                matches.append(drv_path)

            # Also check input derivations
            input_drvs = drv_info.get("inputDrvs", {})
            for input_drv in input_drvs.keys():
                if search_term in input_drv and input_drv not in matches:
                    matches.append(input_drv)

        return list(set(matches))  # Remove duplicates
    except json.JSONDecodeError as e:
        print(f"❌ Failed to parse derivation JSON: {e}")
        return []


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

    # First, look for exact matches in the derivation
    matches = find_package_in_derivation(flake_output, search_term)
    if matches:
        print(
            f"✅ Found {len(matches)} package(s) matching '{search_term}' in the system dependencies:"
        )
        for i, match in enumerate(matches, 1):
            # Extract a more readable name from the derivation path
            readable_name = match.split("/")[-1] if "/" in match else match
            print(f"  {i}. {readable_name}")

        if len(matches) <= 3:  # Auto-analyze if not too many matches
            for i, match in enumerate(matches, 1):
                readable_name = match.split("/")[-1] if "/" in match else match
                print(f"\n🔎 Analyzing dependency path #{i}: {readable_name}")
                # Use the full derivation path
                full_drv_path = (
                    f"/nix/store/{match}"
                    if not match.startswith("/nix/store/")
                    else match
                )
                subprocess.run(
                    ["nix", "why-depends", "--derivation", flake_output, full_drv_path]
                )
        else:
            print(
                "\n🔎 Too many matches to analyze automatically. You can analyze specific dependencies with:"
            )
            for match in matches[:3]:  # Show first 3 to avoid spam
                print(f"   nix why-depends --derivation {flake_output} {match}")
            if len(matches) > 3:
                print(f"   ... and {len(matches) - 3} more")
        return True

    print(f"🔍 No direct matches for '{search_term}' found in system dependencies.")
    print(f"🔎 Checking if '{search_term}' exists as a standalone package...")

    # Fallback: try common package patterns and check if system depends on them
    search_targets = [
        f"nixpkgs#{search_term}",  # Direct package
        f"nixpkgs#rubyPackages.{search_term}",  # Ruby gem
        f"nixpkgs#python3Packages.{search_term}",  # Python package
        f"nixpkgs#nodePackages.{search_term}",  # Node package
        f".#{search_term}",  # Local package
    ]

    found_packages = []
    for target in search_targets:
        success, stdout, stderr = run_safe(
            ["nix", "eval", "--raw", target, "--apply", "toString"]
        )
        if success:
            found_packages.append(target)

    if found_packages:
        print(f"📦 Found {len(found_packages)} package(s) that match '{search_term}':")
        for pkg in found_packages:
            print(f"  - {pkg}")

        print("\n🔎 Checking which ones your system actually depends on...")
        dependencies_found = []

        for pkg in found_packages:
            print(f"   Checking {pkg}...")
            success, stdout, stderr = run_safe(
                ["nix", "why-depends", "--derivation", flake_output, pkg]
            )
            if success and "does not depend on" not in stdout:
                dependencies_found.append(pkg)
                print(f"   ✅ System depends on {pkg}")
            else:
                print(f"   ❌ System does not depend on {pkg}")

        if dependencies_found:
            print(f"\n🎯 Found {len(dependencies_found)} actual dependencies!")
            for dep in dependencies_found:
                print(f"\n🔎 Dependency path for {dep}:")
                subprocess.run(
                    ["nix", "why-depends", "--derivation", flake_output, dep]
                )
        else:
            print("\n❌ None of the found packages are actually used by your system.")
            print(
                f"💡 Your system configuration doesn't depend on any package matching '{search_term}'"
            )
    else:
        print(f"❌ No packages found matching '{search_term}'")
        print("💡 Try using the exact package name or search manually with:")
        print(f"   nix search nixpkgs {search_term}")
        print(
            "   Then use: nix why-depends --derivation {flake_output} nixpkgs#<exact-package-name>"
        )

    return len(found_packages) > 0


def main():
    if len(sys.argv) < 3:
        print("Usage: why-depends [--fast] <host-name-or-flake-output> <partial-pname>")
        print()
        print("Examples:")
        print("  why-depends khanelinix chromium-unwrapped")
        print("  why-depends --fast khanelimac firefox")
        print(
            "  why-depends .#nixosConfigurations.khanelinix.config.system.build.toplevel chromium-unwrapped"
        )
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

            # Check nixOS first
            exists, reason = check_config_exists_fast(nixos_path)
            if exists:
                flake_output = nixos_path
                print(f"✅ Found NixOS configuration: {flake_output}")
            else:
                if reason == "not_in_nixos":
                    print(
                        "⚠️  Host not found in nixosConfigurations, trying darwinConfigurations..."
                    )

                # Check darwin
                exists, reason = check_config_exists_fast(darwin_path)
                if exists:
                    flake_output = darwin_path
                    print(f"✅ Found Darwin configuration: {flake_output}")
                else:
                    if reason == "not_in_darwin":
                        print(
                            f"❌ Host '{first_arg}' not found in either nixosConfigurations or darwinConfigurations."
                        )
                    else:
                        print(f"❌ Error checking host '{first_arg}': {reason}")
                    print(
                        "💡 Make sure the host name matches a configuration in your flake."
                    )
                    print(
                        "   You can check available configurations with: nix flake show"
                    )
                    sys.exit(1)
        else:
            # Original behavior - try building with better error messages
            print("🔍 Trying NixOS configuration...")
            success, reason = nix_build_safe(nixos_path)
            if success:
                flake_output = nixos_path
            else:
                if reason == "not_in_nixos":
                    print(
                        "⚠️  Host not found in nixosConfigurations, trying darwinConfigurations..."
                    )
                elif reason == "build_failed":
                    print("❌ NixOS configuration exists but failed to build")
                    print(
                        "💡 You can try fast mode to analyze dependencies without building:"
                    )
                    print(f"   why-depends --fast {first_arg} {search_term}")
                    sys.exit(1)

                print("🔍 Trying Darwin configuration...")
                success, reason = nix_build_safe(darwin_path)
                if success:
                    flake_output = darwin_path
                else:
                    if reason == "not_in_darwin":
                        print(
                            f"❌ Host '{first_arg}' not found in either nixosConfigurations or darwinConfigurations."
                        )
                    elif reason == "build_failed":
                        print("❌ Darwin configuration exists but failed to build")
                        print(
                            "💡 You can try fast mode to analyze dependencies without building:"
                        )
                        print(f"   why-depends --fast {first_arg} {search_term}")
                        sys.exit(1)
                    else:
                        print(f"❌ Error with Darwin configuration: {reason}")

                    print(
                        "💡 Make sure the host name matches a configuration in your flake."
                    )
                    print(
                        "   You can check available configurations with: nix flake show"
                    )
                    sys.exit(1)

    if fast_mode:
        print("🚀 Using fast derivation analysis (no building required)")
        run_why_depends_derivation(flake_output, search_term)
    else:
        # If we got here with a provided flake output, build it
        if first_arg.startswith(".#"):
            success, reason = nix_build_safe(flake_output)
            if not success:
                if reason == "build_failed":
                    print("❌ Configuration exists but failed to build")
                    print(
                        "💡 You can try fast mode to analyze dependencies without building:"
                    )
                    print(f"   why-depends --fast {first_arg} {search_term}")
                else:
                    print(f"❌ Failed to build {flake_output}: {reason}")
                sys.exit(1)

        toplevel_path = get_result_path()
        print(f"📦 Toplevel path: {toplevel_path}")

        matches = find_matches(toplevel_path, search_term)
        if not matches:
            print(f"❌ No match found for '{search_term}' in the closure.")
            print("💡 You can try fast mode to search in derivation dependencies:")
            print(f"   why-depends --fast {first_arg} {search_term}")
            sys.exit(1)

        print("✅ Found match(es):")
        for m in matches:
            print(m)

        dep_path = pick_match(matches)
        run_why_depends(toplevel_path, dep_path)


if __name__ == "__main__":
    main()
