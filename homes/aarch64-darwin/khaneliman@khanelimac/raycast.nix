{
  config,
  lib,
  pkgs,
  ...
}:
{
  xdg.configFile."raycast/script-commands/khanelimac-sessions.sh" =
    lib.mkIf config.khanelinix.programs.graphical.apps.raycast.enable
      {
        executable = true;
        text = ''
          #!${pkgs.runtimeShell}
          # @raycast.schemaVersion 1
          # @raycast.title Open Khanelimac
          # @raycast.mode compact
          # @raycast.icon terminal
          # @raycast.description Open an interactive sesh session for Khanelimac.


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

          exec kitty --single-instance -d "$HOME" -- zsh -lc "sesh connect khanelinix"
        '';
      };
}
