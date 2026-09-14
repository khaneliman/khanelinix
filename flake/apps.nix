_: {
  perSystem =
    { pkgs, lib, ... }:
    let
      inputGroups = {
        core = {
          description = "Core Nix ecosystem";
          inputs = [
            "nixpkgs"
            "nixpkgs-unstable"
            "nixpkgs-master"
            "flake-compat"
            "flake-parts"
            "systems"
          ];
        };

        system = {
          description = "System management";
          inputs = [
            "disko"
            "fast-nix-gc"
            "home-manager"
            "jovian"
            "lanzaboote"
            "nix-darwin"
            "nix-rosetta-builder"
            "nixos-wsl"
            "sops-nix"
          ];
        };

        apps = {
          description = "Applications & packages";
          inputs = [
            "adv360-zmk"
            "anyrun-nixos-options"
            "catppuccin"
            "codex-desktop-linux"
            "firefox-addons"
            "hermes-agent"
            "khanelivim"
            "llm-agents"
            "mcp-servers-nix"
            "niri"
            "nix-flatpak"
            "nix-index-database"
            "plasma-manager"
            "stylix"
            "t3code"
            "tokyonight"
            "waybar"
            "yazi-flavors"
            "zmk-nix"
          ];
        };
      };

      mkUpdateApp =
        name:
        { description, inputs }:
        {
          type = "app";
          meta.description = "Update ${description} inputs";
          program = lib.getExe (
            pkgs.writeShellApplication {
              name = "update-${name}";
              meta = {
                mainProgram = "update-${name}";
                description = "Update ${description} inputs";
              };
              text = ''
                set -euo pipefail

                echo "🔄 Updating ${description} inputs..."
                nix flake update ${lib.concatStringsSep " " inputs}

                echo "✅ ${description} inputs updated successfully!"
              '';
            }
          );
        };

      groupApps = lib.mapAttrs' (
        name: value: lib.nameValuePair "update-${name}" (mkUpdateApp name value)
      ) inputGroups;

      mkFastBuildApp = name: flakeRef: description: {
        type = "app";
        meta.description = description;
        program = lib.getExe (
          pkgs.writeShellApplication {
            name = "fast-build-${name}";
            runtimeInputs = [ pkgs.nix-fast-build ];
            text = ''
              nix-fast-build --flake ${flakeRef} --no-link "$@"
            '';
          }
        );
      };
    in
    {
      apps = groupApps // {
        update-all = {
          type = "app";
          meta.description = "Update all flake inputs";
          program = lib.getExe (
            pkgs.writeShellApplication {
              name = "update-all";
              meta = {
                mainProgram = "update-all";
                description = "Update all flake inputs";
              };
              text = ''
                set -euo pipefail

                echo "🔄 Updating main flake lock..."
                nix flake update

                echo "🔄 Updating dev flake lock..."
                nix flake update --flake ./flake/dev

                echo "✅ All flake locks updated successfully!"
              '';
            }
          );
        };

        closure-analyzer = {
          type = "app";
          meta.description = "Analyze Nix store closures";
          program = lib.getExe (pkgs.callPackage ../packages/closure-analyzer/package.nix { });
        };

        fast-build-checks =
          mkFastBuildApp "checks" ".#checks"
            "Evaluate and build checks with nix-fast-build";
        fast-build-packages =
          mkFastBuildApp "packages" ".#packages"
            "Evaluate and build packages with nix-fast-build";

        update-plugins =
          let
            pythonWithRich = pkgs.python3.withPackages (ps: with ps; [ rich ]);
          in
          {
            type = "app";
            meta.description = "Update plugin definitions/locks";
            program = lib.getExe (
              pkgs.writeShellApplication {
                name = "update-plugins";
                runtimeInputs = [
                  pkgs.git
                  pythonWithRich
                ];
                text = ''
                  ${pythonWithRich}/bin/python3 ${./apps/scripts/update_plugins.py}
                '';
              }
            );
          };

        update-packages = {
          type = "app";
          meta.description = "Update local flake packages in separate commits";
          program = lib.getExe (
            pkgs.writeShellApplication {
              name = "update-packages";
              runtimeInputs = [
                pkgs.git
                pkgs.nix
                pkgs.nix-update
                pkgs.python3
              ];
              text = ''
                ${pkgs.python3}/bin/python3 ${./apps/scripts/update_packages.py} "$@"
              '';
            }
          );
        };

        deploy =
          let
            hosts = import ../modules/common/programs/terminal/tools/ssh/hosts.nix;

            formatRow =
              name: cfg:
              let
                pad =
                  str: n:
                  let
                    s = toString str;
                    diff = n - (lib.stringLength s);
                  in
                  if diff > 0 then s + lib.concatStrings (lib.genList (_: " ") diff) else "${s} ";
              in
              "${pad name 15}${pad cfg.hostname 22}${pad cfg.username 12}${cfg.system}";

            tableHeader = "NAME           HOSTNAME              USER        SYSTEM";
            tableRows = lib.concatStringsSep "\n" (lib.mapAttrsToList formatRow hosts);
            hostTable = "${tableHeader}\n${tableRows}";

            hostCases = lib.concatStringsSep "\n" (
              lib.mapAttrsToList (name: cfg: ''
                "${name}")
                  target_hostname="${cfg.hostname}"
                  target_user="${cfg.username}"
                  target_system="${cfg.system}"
                  ;;
              '') hosts
            );
          in
          {
            type = "app";
            meta.description = "Deploy a host configuration remotely";
            program = lib.getExe (
              pkgs.writeShellApplication {
                name = "deploy";
                meta = {
                  mainProgram = "deploy";
                  description = "Deploy a host configuration remotely";
                };
                runtimeInputs = [
                  pkgs.openssh
                  (pkgs.nixos-rebuild-ng or pkgs.nixos-rebuild)
                ];
                text = ''
                  host_table='${hostTable}'

                  print_usage() {
                    echo "Usage: deploy <host> [switch|boot|test|build] [extra args...]"
                    echo
                    echo "Available hosts:"
                    echo "$host_table"
                  }

                  if [ $# -eq 0 ]; then
                    print_usage
                    exit 1
                  fi

                  target_name="$1"
                  shift

                  action="switch"
                  if [ $# -gt 0 ]; then
                    case "$1" in
                      switch|boot|test|build)
                        action="$1"
                        shift
                        ;;
                      -*)
                        ;;
                      *)
                        action="$1"
                        shift
                        ;;
                    esac
                  fi

                  case "$target_name" in
                  ${hostCases}
                    *)
                      echo "Error: Unknown host '$target_name'" >&2
                      echo >&2
                      print_usage >&2
                      exit 1
                      ;;
                  esac

                  current_host="$(hostname 2>/dev/null || uname -n)"
                  current_short="''${current_host%%.*}"
                  target_short="''${target_hostname%%.*}"

                  if [ "$target_name" = "$current_host" ] || [ "$target_name" = "$current_short" ] || \
                     [ "$target_hostname" = "$current_host" ] || [ "$target_short" = "$current_short" ]; then
                    echo "Target host '$target_name' matches current machine ('$current_host')." >&2
                    echo "Use 'nixre' for local rebuilds." >&2
                    exit 1
                  fi

                  case "$target_system" in
                    nixos)
                      case "$action" in
                        switch|boot|test|build) ;;
                        *)
                          echo "Error: Invalid action '$action' for NixOS host. Expected: switch, boot, test, build" >&2
                          exit 1
                          ;;
                      esac

                      nixos-rebuild "$action" \
                        --flake ".#$target_name" \
                        --target-host "$target_user@$target_hostname" \
                        --sudo \
                        "$@"
                      ;;

                    darwin)
                      case "$action" in
                        switch|build) ;;
                        boot|test)
                          echo "Error: Action '$action' is not supported on Darwin hosts (supported: switch, build)" >&2
                          exit 1
                          ;;
                        *)
                          echo "Error: Invalid action '$action' for Darwin host. Expected: switch, build" >&2
                          exit 1
                          ;;
                      esac

                      if [ "$action" = "build" ]; then
                        nix build ".#darwinConfigurations.''${target_name}.system" "$@"
                        exit 0
                      fi

                      # nix-darwin does not support remote deployment via --target-host.
                      # In nix-darwin's darwin-rebuild.sh (pkgs/nix-tools/darwin-rebuild.sh), 'switch'
                      # invokes 'nix build' on the target host rather than accepting a pre-built store path.
                      # Upstream nix-darwin (modules/system/default.nix) documents activating pre-built
                      # systems via '$systemConfig/sw/bin/darwin-rebuild activate' or running '$systemConfig/activate'
                      # as root. In darwin-rebuild.sh, 'activate' simply calls '$systemConfig/activate'
                      # after verifying root privileges. We directly execute the documented '<result>/activate'
                      # script as root on the target host.
                      out_path="$(nix build ".#darwinConfigurations.''${target_name}.system" --no-link --print-out-paths "$@")"
                      nix copy --to "ssh-ng://$target_user@$target_hostname" "$out_path"

                      ssh_opts=()
                      if [ -t 0 ]; then
                        ssh_opts+=("-t")
                      fi
                      # shellcheck disable=SC2029
                      ssh "''${ssh_opts[@]}" "$target_user@$target_hostname" sudo "$out_path/activate"
                      ;;

                    *)
                      echo "Error: Unknown system '$target_system' for host '$target_name'" >&2
                      exit 1
                      ;;
                  esac
                '';
              }
            );
          };

        update-vicinae-extensions = {
          type = "app";
          meta.description = "Update pinned Vicinae Raycast extensions";
          program = lib.getExe (
            pkgs.writeShellApplication {
              name = "update-vicinae-extensions";
              runtimeInputs = [
                pkgs.git
                pkgs.python3
              ];
              text = ''
                ${pkgs.python3}/bin/python3 ${./apps/scripts/update_vicinae_extensions.py}
              '';
            }
          );
        };
      };
    };
}
