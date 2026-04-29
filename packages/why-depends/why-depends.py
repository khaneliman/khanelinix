#!/usr/bin/env python3

import argparse
import json
import subprocess
import sys


def run(cmd, capture_output=True, check=True, text=True):
    return subprocess.run(
        cmd, capture_output=capture_output, check=check, text=text
    ).stdout.strip()


def run_safe(cmd, capture_output=True, text=True):
    """Run command and return (success, stdout, stderr)."""
    try:
        result = subprocess.run(
            cmd, capture_output=capture_output, text=text, check=False
        )
        return result.returncode == 0, result.stdout.strip(), result.stderr.strip()
    except Exception as e:
        return False, "", str(e)


class DerivationShowParseError(ValueError):
    """Raised when `nix derivation show -r` output is not in a supported shape."""


def parse_derivation_show_output(raw_output):
    """Normalize legacy and envelope `nix derivation show -r` JSON formats."""
    payload = json.loads(raw_output)
    if not isinstance(payload, dict):
        raise DerivationShowParseError(
            f"top-level JSON type was {type(payload).__name__}; expected object"
        )

    derivation_map = payload.get("derivations", payload)
    if not isinstance(derivation_map, dict):
        raise DerivationShowParseError("'derivations' key exists but is not an object")

    bad_entries = [
        key for key, value in derivation_map.items() if not isinstance(value, dict)
    ]
    if bad_entries:
        raise DerivationShowParseError(
            "derivation map has non-object entries for: " + ", ".join(bad_entries[:3])
        )

    return derivation_map


def resolve_host_to_flake_output(host_name):
    """Convert a host name to the appropriate flake output path."""
    nixos_path = f".#nixosConfigurations.{host_name}.config.system.build.toplevel"
    darwin_path = f".#darwinConfigurations.{host_name}.system"

    print(f"🎯 Trying to resolve host '{host_name}'...")
    return nixos_path, darwin_path


def check_config_exists_fast(flake_output):
    """Fast check if configuration exists using derivation show."""
    success, _, stderr = run_safe(["nix", "derivation", "show", flake_output])
    if success:
        return True, "exists"

    if "does not provide attribute" in stderr:
        if "nixosConfigurations" in flake_output:
            return False, "not_in_nixos"
        if "darwinConfigurations" in flake_output:
            return False, "not_in_darwin"

    return False, "unknown_error"


def nix_build_safe(flake_output, emit_out_path=False):
    """Build with better error classification."""
    print(f"🔨 Building {flake_output}...")

    build_command = ["nix", "build"]
    if emit_out_path:
        build_command.extend(["--no-link", "--print-out-paths"])
    build_command.append(flake_output)

    success, stdout, stderr = run_safe(build_command)
    out_path = None
    if success and emit_out_path:
        out_paths = [line.strip() for line in stdout.splitlines() if line.strip()]
        if out_paths:
            out_path = out_paths[0]
        else:
            return False, "missing_out_path", None

    if success:
        return True, "success", out_path

    if "does not provide attribute" in stderr:
        if "nixosConfigurations" in flake_output:
            return False, "not_in_nixos", None
        if "darwinConfigurations" in flake_output:
            return False, "not_in_darwin", None
        return False, "config_not_found", None
    if "Cannot build" in stderr or "builder failed" in stderr:
        return False, "build_failed", None

    return False, "unknown_error", None


def find_matches(closure_path, search_term):
    print(f"🔍 Searching for dependency matching '{search_term}'...")
    refs = run(["nix-store", "-qR", closure_path]).splitlines()
    return sorted([ref for ref in refs if search_term in ref])


def find_package_in_derivation(flake_output, search_term):
    """Search for packages in the derivation graph that match the search term."""
    print(f"🔍 Searching for '{search_term}' in derivation dependencies...")

    success, stdout, stderr = run_safe(
        ["nix", "derivation", "show", "-r", flake_output]
    )
    if not success:
        print(f"❌ Failed to get derivation info: {stderr}")
        return []

    try:
        derivation_map = parse_derivation_show_output(stdout)
        matches = []

        for drv_path, drv_info in derivation_map.items():
            if search_term in drv_path:
                matches.append(drv_path)

            name = drv_info.get("name", "")
            if search_term in name:
                matches.append(drv_path)

            input_drvs = drv_info.get("inputDrvs", {})
            if isinstance(input_drvs, dict):
                for input_drv in input_drvs.keys():
                    if search_term in input_drv and input_drv not in matches:
                        matches.append(input_drv)

        return sorted(set(matches))
    except DerivationShowParseError as e:
        print(f"❌ Unexpected derivation JSON shape: {e}")
        return []
    except json.JSONDecodeError as e:
        print(f"❌ Failed to parse derivation JSON: {e}")
        return []


def to_store_path(reference):
    """Turn derivation-like references into absolute /nix/store paths."""
    if not isinstance(reference, str):
        return None
    reference = reference.strip()
    if not reference:
        return None
    if reference.startswith("/nix/store/"):
        return reference
    if "/" in reference:
        return None
    return f"/nix/store/{reference}"


def pick_match(matches):
    if not matches:
        return None
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


def run_why_depends(toplevel_path, dep_path, with_derivation=False):
    print("🔎 Running nix why-depends:\n")
    command = ["nix", "why-depends"]
    if with_derivation:
        command.append("--derivation")
    command.extend([toplevel_path, dep_path])
    return subprocess.run(command)


def run_why_depends_derivation(flake_output, search_term):
    """Use derivation-based analysis with no build."""
    matches = find_package_in_derivation(flake_output, search_term)

    if matches:
        print(
            f"✅ Found {len(matches)} package(s) matching '{search_term}' in the system dependencies:"
        )
        for i, match in enumerate(matches, 1):
            readable_name = match.split("/")[-1] if "/" in match else match
            print(f"  {i}. {readable_name}")

        normalized_matches = [match for match in map(to_store_path, matches) if match]
        if len(normalized_matches) < len(matches):
            skipped = len(matches) - len(normalized_matches)
            print(f"⚠️  Skipping {skipped} non-derivation match(es) from auto-analysis.")

        if normalized_matches:
            if len(normalized_matches) <= 3:
                for i, match in enumerate(normalized_matches, 1):
                    readable_name = match.split("/")[-1] if "/" in match else match
                    print(f"\n🔎 Analyzing dependency path #{i}: {readable_name}")
                    run_why_depends(flake_output, match, True)
            else:
                print(
                    "\n🔎 Too many matches to analyze automatically. You can analyze specific dependencies with:"
                )
                for match in normalized_matches[:3]:
                    print(f"   nix why-depends --derivation {flake_output} {match}")
                if len(normalized_matches) > 3:
                    print(f"   ... and {len(normalized_matches) - 3} more")
        else:
            print("❌ No supported derivation references found for auto-analysis.")

        return True

    print(f"🔍 No direct matches for '{search_term}' found in system dependencies.")
    print(f"🔎 Checking if '{search_term}' exists as a standalone package...")

    search_targets = [
        f"nixpkgs#{search_term}",
        f"nixpkgs#rubyPackages.{search_term}",
        f"nixpkgs#python3Packages.{search_term}",
        f"nixpkgs#nodePackages.{search_term}",
        f".#{search_term}",
    ]

    found_packages = []
    for target in search_targets:
        success, _, _ = run_safe(
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
            success, stdout, _ = run_safe(
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
                run_why_depends(flake_output, dep, True)
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

    return bool(found_packages)


def parse_args():
    parser = argparse.ArgumentParser(
        description="Trace why a package exists in a Nix system closure.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Examples:\n"
            "  why-depends khanelinix chromium-unwrapped\n"
            "  why-depends --fast khanelimac firefox\n"
            "  why-depends .#nixosConfigurations.khanelinix.config.system.build.toplevel chromium-unwrapped"
        ),
    )
    parser.add_argument("target", help="Host name or flake output path.")
    parser.add_argument(
        "partial_pname", help="Partial package/dependency name to search."
    )
    parser.add_argument(
        "--fast",
        action="store_true",
        help="Use derivation analysis (no build required).",
    )
    return parser.parse_args()


def show_host_not_found_error(host_name, reason):
    if reason == "not_in_nixos":
        print(
            f"❌ Host '{host_name}' not found in either nixosConfigurations or darwinConfigurations."
        )
        return
    if reason == "not_in_darwin":
        print(
            f"❌ Host '{host_name}' not found in either nixosConfigurations or darwinConfigurations."
        )
        return

    print(f"❌ Failed to resolve host '{host_name}': {reason}")
    print("💡 Make sure the host name matches a configuration in your flake.")
    print("   You can check available configurations with: nix flake show")


def main():
    args = parse_args()
    first_arg = args.target
    search_term = args.partial_pname
    fast_mode = args.fast

    flake_output = None
    toplevel_path = None

    if first_arg.startswith(".#"):
        flake_output = first_arg
        print(f"🎯 Using provided flake output: {flake_output}")

        if not fast_mode:
            success, reason, out_path = nix_build_safe(flake_output, emit_out_path=True)
            if not success:
                if reason == "build_failed":
                    print("❌ Configuration exists but failed to build")
                    print(
                        "💡 You can try fast mode to analyze dependencies without building:"
                    )
                    print(f"   why-depends --fast {first_arg} {search_term}")
                elif reason == "missing_out_path":
                    print("❌ Build did not return an output path.")
                else:
                    print(f"❌ Failed to build {flake_output}: {reason}")
                sys.exit(1)
            toplevel_path = out_path
    else:
        nixos_path, darwin_path = resolve_host_to_flake_output(first_arg)

        if fast_mode:
            print("🔍 Fast mode: checking derivations...")
            exists, reason = check_config_exists_fast(nixos_path)
            if exists:
                flake_output = nixos_path
                print(f"✅ Found NixOS configuration: {flake_output}")
            else:
                if reason == "not_in_nixos":
                    print(
                        "⚠️  Host not found in nixosConfigurations, trying darwinConfigurations..."
                    )
                exists, reason = check_config_exists_fast(darwin_path)
                if exists:
                    flake_output = darwin_path
                    print(f"✅ Found Darwin configuration: {flake_output}")
                else:
                    show_host_not_found_error(first_arg, reason)
                    print(
                        "💡 You can check available configurations with: nix flake show"
                    )
                    sys.exit(1)
        else:
            print("🔍 Trying NixOS configuration...")
            success, reason, out_path = nix_build_safe(nixos_path, emit_out_path=True)
            if success:
                flake_output = nixos_path
                toplevel_path = out_path
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
                success, reason, out_path = nix_build_safe(
                    darwin_path, emit_out_path=True
                )
                if success:
                    flake_output = darwin_path
                    toplevel_path = out_path
                else:
                    if reason == "not_in_darwin":
                        show_host_not_found_error(first_arg, reason)
                        print(
                            "💡 You can check available configurations with: nix flake show"
                        )
                        sys.exit(1)
                    if reason == "build_failed":
                        print("❌ Darwin configuration exists but failed to build")
                        print(
                            "💡 You can try fast mode to analyze dependencies without building:"
                        )
                        print(f"   why-depends --fast {first_arg} {search_term}")
                        sys.exit(1)
                    print(f"❌ Error with Darwin configuration: {reason}")
                    print(
                        "💡 Make sure the host name matches a configuration in your flake."
                    )
                    print(
                        "   You can check available configurations with: nix flake build"
                    )
                    sys.exit(1)

    if not flake_output:
        print(f"❌ Could not resolve a configuration for '{first_arg}'.")
        sys.exit(1)

    if fast_mode:
        print("🚀 Using fast derivation analysis (no building required)")
        run_why_depends_derivation(flake_output, search_term)
        return

    if not toplevel_path:
        print("🔍 Ensuring build output path...")
        _, reason, toplevel_path = nix_build_safe(flake_output, emit_out_path=True)
        if not toplevel_path:
            print("❌ Build did not return an output path.")
            if reason == "missing_out_path":
                print(
                    "💡 Try again or inspect: nix build --print-out-paths <flake-output>"
                )
            else:
                print(f"❌ Failed while resolving build output path: {reason}")
            sys.exit(1)

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
