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
          ];
        };

        system = {
          description = "System management";
          inputs = [
            "disko"
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
            "anyrun-nixos-options"
            "catppuccin"
            "firefox-addons"
            "hypr-socket-watch"
            "hyprland"
            "khanelivim"
            "nh"
            "nix-flatpak"
            "nix-index-database"
            "stylix"
            "waybar"
            "yazi-flavors"
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
                cd flake/dev && nix flake update

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
      };
    };
}
