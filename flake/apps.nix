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
            "firefox-addons"
            "hermes-agent"
            "khanelivim"
            "llm-agents"
            "mcp-servers-nix"
            "nh"
            "niri"
            "nix-flatpak"
            "nix-index-database"
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
