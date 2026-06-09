{
  config,
  osConfig ? { },
  lib,
  pkgs,

  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    listToAttrs
    mapAttrsToList
    nameValuePair
    ;

  cfg = config.khanelinix.programs.graphical.apps.raycast;

  mkScript =
    {
      title,
      description,
      body,
      icon ? "command-symbol",
      mode ? "compact",
      argument1 ? null,
    }:
    ''
      #!${pkgs.runtimeShell}
      # @raycast.schemaVersion 1
      # @raycast.title ${title}
      # @raycast.mode ${mode}
      # @raycast.icon ${icon}
      # @raycast.description ${description}
      ${lib.optionalString (argument1 != null) "# @raycast.argument1 ${builtins.toJSON argument1}"}

      set -euo pipefail
      export PATH=${
        lib.escapeShellArg (
          lib.concatStringsSep ":" [
            "/etc/profiles/per-user/${config.home.username}/bin"
            "/run/current-system/sw/bin"
            "/nix/var/nix/profiles/default/bin"
            "/opt/homebrew/bin"
            "/usr/local/bin"
            "/usr/bin"
            "/bin"
            "/usr/sbin"
            "/sbin"
          ]
        )
      }

      ${body}
    '';

  mkScriptEntry =
    {
      file,
      title,
      description,
      body,
      icon ? "command-symbol",
      mode ? "compact",
      argument1 ? null,
    }:
    nameValuePair "raycast/script-commands/${file}" {
      executable = true;
      text = mkScript {
        inherit
          title
          description
          body
          icon
          mode
          argument1
          ;
      };
    };
in
{
  options.khanelinix.programs.graphical.apps.raycast.enable =
    mkEnableOption "Raycast script commands";

  config = mkIf cfg.enable {
    # Raycast stores script directory registrations in private app state.
    # Add ~/.config/raycast/script-commands once from Raycast Settings >
    # Script Commands > Add Script Directory; scripts below stay declarative.
    xdg.configFile = listToAttrs (
      [
        (mkScriptEntry {
          file = "nix-switch.sh";
          title = "Nix Switch";
          description = "Switch current nix-darwin configuration.";
          icon = "hammer";
          body = "exec nh darwin switch";
        })
        (mkScriptEntry {
          file = "nix-switch-fast.sh";
          title = "Nix Switch Fast";
          description = "Switch nix-darwin with parallel Nix jobs.";
          icon = "bolt";
          body = ''
            NIX_CONFIG=$'max-jobs = auto\ncores = 0'
            export NIX_CONFIG
            exec nh darwin switch
          '';
        })
        (mkScriptEntry {
          file = "open-khanelinix.sh";
          title = "Open Khanelinix";
          description = "Open khanelinix workspace in Kitty and Zellij.";
          icon = "terminal";
          body = ''exec kitty --single-instance -d "$HOME/khanelinix" -- zellij'';
        })
        (mkScriptEntry {
          file = "sesh-connect.sh";
          title = "Sesh Connect";
          description = "Open named sesh session in Kitty.";
          icon = "terminal";
          argument1 = {
            type = "text";
            placeholder = "session";
            optional = true;
          };
          body = ''
            session="''${1:-khanelinix}"
            export SESSION="$session"
            exec kitty --single-instance -d "$HOME" -- zsh -lc 'sesh connect "$SESSION"'
          '';
        })
      ]
      ++
        mapAttrsToList
          (
            name: service:
            mkScriptEntry {
              file = "restart-${name}.sh";
              inherit (service)
                title
                description
                icon
                ;
              body = ''exec launchctl kickstart -k "gui/$(id -u)/${service.launchdTarget}"'';
            }
          )
          {
            sketchybar = {
              title = "Restart Sketchybar";
              description = "Restart Home Manager Sketchybar launch agent.";
              icon = "bar-chart";
              launchdTarget = "org.nix-community.home.sketchybar";
            };
            skhd = {
              title = "Restart Skhd";
              description = "Restart Home Manager skhd launch agent.";
              icon = "keyboard";
              launchdTarget = "org.nix-community.home.skhd";
            };
            yabai = {
              title = "Restart Yabai";
              description = "Restart nix-darwin yabai launch agent.";
              icon = "window";
              launchdTarget = "org.nixos.yabai";
            };
          }
      ++ lib.optionals (osConfig.networking.hostName or "" == "khanelimac") [
        (mkScriptEntry {
          file = "khanelimac-sessions.sh";
          title = "Open Khanelimac";
          description = "Open an interactive sesh session for Khanelimac.";
          icon = "terminal";
          body = ''exec kitty --single-instance -d "$HOME" -- zsh -lc "sesh connect khanelinix"'';
        })
      ]
    );
  };
}
