{ writeShellApplication, coreutils, ... }:
writeShellApplication {
  name = "nixos-needsreboot";

  meta = {
    mainProgram = "nixos-needsreboot";
  };

  checkPhase = "";

  runtimeInputs = [ coreutils ];

  text = ''
    set -euo pipefail

    version="khanelinix-local"
    booted_system="/run/booted-system"
    current_system="/nix/var/nix/profiles/system"
    reboot_file="/run/reboot-required"
    write_reboot_file=true

    for arg in "$@"; do
      case "$arg" in
        --version)
          echo "nixos-needsreboot ''${version}"
          exit 0
          ;;
        --dry-run)
          write_reboot_file=false
          ;;
        *)
          echo "usage: nixos-needsreboot [--dry-run] [--version]" >&2
          exit 64
          ;;
      esac
    done

    if [[ ! -e "$current_system" || ! -e "$booted_system" ]]; then
      echo "nixos-needsreboot only works on a booted NixOS system" >&2
      exit 1
    fi

    if [[ "$EUID" -ne 0 && "$write_reboot_file" == true ]]; then
      echo "refusing to write $reboot_file without root; use --dry-run" >&2
      exit 1
    fi

    store_path_for() {
      local link="$1"
      local target name

      target=$(readlink -f "$link")
      case "$target" in
        /nix/store/*)
          name="''${target#/nix/store/}"
          printf '/nix/store/%s\n' "''${name%%/*}"
          ;;
        *)
          printf '%s\n' "$target"
          ;;
      esac
    }

    kernel_release() {
      local modules="$1/lib/modules"
      local release

      if [[ -d "$modules" ]]; then
        for release in "$modules"/*; do
          [[ -d "$release" ]] || continue
          basename "$release"
          return
        done
      fi

      true
    }

    systemd_release() {
      local name

      name=$(basename "$1")
      printf '%s\n' "''${name#*-systemd-}"
    }

    describe_change() {
      local label="$1"
      local old="$2"
      local new="$3"

      if [[ -n "$old" && -n "$new" && "$old" != "$new" ]]; then
        printf '%s changed: %s -> %s\n' "$label" "$old" "$new"
      else
        printf '%s changed\n' "$label"
      fi
    }

    compare_component() {
      local label="$1"
      local old_link="$2"
      local new_link="$3"
      local release_command="$4"
      local old_store new_store old_release new_release

      [[ -e "$old_link" && -e "$new_link" ]] || return 0

      old_store=$(store_path_for "$old_link")
      new_store=$(store_path_for "$new_link")
      [[ "$old_store" != "$new_store" ]] || return 0

      old_release=$("$release_command" "$old_store" || true)
      new_release=$("$release_command" "$new_store" || true)

      describe_change "$label" "$old_release" "$new_release"
    }

    if [[ -s "$reboot_file" ]]; then
      cat "$reboot_file"
      exit 2
    fi

    if [[ "$(readlink -f "$booted_system")" == "$(readlink -f "$current_system")" ]]; then
      echo "booted generation already matches the current system profile" >&2
      exit 0
    fi

    reason="$(
      compare_component "kernel" "$booted_system/kernel-modules" "$current_system/kernel-modules" kernel_release
      compare_component "systemd" "$booted_system/systemd" "$current_system/systemd" systemd_release
    )"

    if [[ -z "$reason" ]]; then
      echo "current generation differs, but kernel and systemd are unchanged" >&2
      exit 0
    fi

    if [[ "$write_reboot_file" == true ]]; then
      printf '%s\n' "$reason" > "$reboot_file"
    else
      echo -n "$reason"
    fi

    exit 2
  '';
}
