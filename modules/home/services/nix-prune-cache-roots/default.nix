{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.khanelinix.services.nix-prune-cache-roots;

  maxAgeDays = 14;
  frequency = "daily";

  # launchd discards output unless told where to put it.
  launchdLog = "${config.home.homeDirectory}/Library/Logs/nix-prune-cache-roots.log";

  pruneCommand = pkgs.writeShellApplication {
    name = "nix-prune-cache-roots";
    runtimeInputs = [ pkgs.findutils ];
    text = ''
      action=(-delete)
      if [ "''${1-}" = --dry-run ]; then
        action=()
      fi

      # Nix registers every out-link it creates here, so this only touches
      # links the garbage collector treats as roots.
      find /nix/var/nix/gcroots/auto -type l \
        -lname ${lib.escapeShellArg "${config.xdg.cacheHome}/*"} -printf '%l\0' |
        while IFS= read -r -d "" link; do
          # A registration outlives its link until the next collection.
          [ -L "$link" ] || continue
          find "$link" -maxdepth 0 -mtime +${toString maxAgeDays} -print "''${action[@]}"
        done
    '';
  };
in
{
  options.khanelinix.services.nix-prune-cache-roots.enable =
    lib.mkEnableOption "removal of stale Nix out-links from the cache directory";

  config = lib.mkIf cfg.enable {
    home.packages = [ pruneCommand ];

    systemd.user = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      services.nix-prune-cache-roots = {
        Unit.Description = "Remove stale Nix out-links from the cache directory";
        Service = {
          Type = "oneshot";
          ExecStart = lib.getExe pruneCommand;
        };
      };

      timers.nix-prune-cache-roots = {
        Unit.Description = "Remove stale Nix out-links from the cache directory ${frequency}";
        Timer = {
          OnCalendar = frequency;
          Persistent = true;
        };
        Install.WantedBy = [ "timers.target" ];
      };
    };

    launchd.agents.nix-prune-cache-roots = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      enable = true;
      # Removing links does not need the Aqua session.
      domain = "user";
      config = {
        ProgramArguments = [ (lib.getExe pruneCommand) ];
        StartCalendarInterval = lib.hm.darwin.mkCalendarInterval frequency;
        StandardOutPath = launchdLog;
        StandardErrorPath = launchdLog;
      };
    };
  };
}
