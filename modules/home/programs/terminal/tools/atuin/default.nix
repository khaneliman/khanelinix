{
  config,
  lib,
  osConfig ? { },
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.terminal.tools.atuin;

  userHome = config.home.homeDirectory;
  atuinSocketPath = "${userHome}/.local/share/atuin/daemon.sock";

  atuinLogPaths = lib.attrByPath [ "khanelinix" "programs" "terminal" "tools" "atuin" "logPaths" ] (
    if pkgs.stdenv.hostPlatform.isDarwin then
      {
        stdout = "${userHome}/Library/Logs/atuin/atuin.out.log";
        stderr = "${userHome}/Library/Logs/atuin/atuin.err.log";
      }
    else
      {
        stdout = "${userHome}/.local/state/atuin/atuin.out.log";
        stderr = "${userHome}/.local/state/atuin/atuin.err.log";
      }
  ) osConfig;
in
{
  options.khanelinix.programs.terminal.tools.atuin = {
    enable = lib.mkEnableOption "atuin";
    enableDebug = lib.mkEnableOption "atuin daemon debug logging";
  };

  config = mkIf cfg.enable {
    home.shellAliases = {
      atuin-prune-failed = "atuin search --exclude-exit 0 --delete \"\"";
      atuin-prune-failed-dry-run = "atuin search --exclude-exit 0 --format \"{exit}\t{time}\t{command}\" | rg '^[1-9][0-9]*\t'";
    };

    launchd.agents.atuin-daemon.config = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      ProgramArguments = [
        "/bin/sh"
        "-c"
        ''
          /bin/wait4path /nix/store || exit 1

          # macOS can leave the socket behind across reboots if the daemon is
          # terminated before its shutdown handler runs.
          if [ -S '${atuinSocketPath}' ] && ! /usr/sbin/lsof '${atuinSocketPath}' >/dev/null 2>&1; then
            rm -f '${atuinSocketPath}'
          fi

          exec ${lib.getExe pkgs.atuin} daemon
        ''
      ];
      StandardErrorPath = atuinLogPaths.stderr;
      StandardOutPath = atuinLogPaths.stdout;
    };

    programs.atuin = {
      enable = true;

      enableBashIntegration = true;
      enableFishIntegration = true;
      enableZshIntegration = true;
      enableNushellIntegration = true;

      daemon = {
        enable = true;
      }
      // lib.optionalAttrs cfg.enableDebug {
        logLevel = "debug";
      };

      # flags = [
      #   "--disable-up-arrow"
      # ];

      # Atuin configuration
      # See: https://docs.atuin.sh/configuration/config/
      settings = {
        enter_accept = true;
        # Filter modes can still be toggled via `ctrl-r`
        filter_mode = "workspace";
        keymap_mode = "auto";
        show_preview = true;
        # NOTE: Whether to store commands that failed.
        # Can be useful to auto prune, but lose commands that might have
        # a simple typo to fix and would need to type again.
        # store_failed = false;
        style = "auto";
        update_check = false;
        workspaces = true;

        # Filter some commands we don't want to accidentally call from history
        history_filter = [
          "^(sudo reboot)$"
          "^(reboot)$"
        ];
      };
    };
  };
}
