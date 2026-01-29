{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib.khanelinix) mkOpt;

  cfg = config.khanelinix.programs.graphical.addons.gamemode;

  powerprofilesctl = lib.getExe' pkgs.power-profiles-daemon "powerprofilesctl";

  defaultStartScript = ''
    ${powerprofilesctl} set performance
    ${lib.getExe' pkgs.libnotify "notify-send"} -u low 'GameMode' 'Performance mode enabled'
  '';

  defaultEndScript = ''
    ${powerprofilesctl} set balanced
    ${lib.getExe' pkgs.libnotify "notify-send"} -u low 'GameMode' 'Balanced mode restored'
  '';
in
{
  options.khanelinix.programs.graphical.addons.gamemode = {
    enable = lib.mkEnableOption "gamemode";
    endscript = mkOpt (with lib.types; nullOr str) null "The script to run when disabling gamemode.";
    startscript = mkOpt (with lib.types; nullOr str) null "The script to run when enabling gamemode.";
    gpuDevice =
      mkOpt lib.types.int 0
        "GPU device index to apply optimizations (check /sys/class/drm/cardN)";
  };

  config =
    let
      startScript =
        if (cfg.startscript == null) then
          pkgs.writeShellScript "gamemode-start" defaultStartScript
        else
          pkgs.writeShellScript "gamemode-start" cfg.startscript;
      endScript =
        if (cfg.endscript == null) then
          pkgs.writeShellScript "gamemode-end" defaultEndScript
        else
          pkgs.writeShellScript "gamemode-end" cfg.endscript;
    in
    lib.mkIf cfg.enable {
      programs.gamemode = {
        enable = true;
        enableRenice = true;

        settings = {
          general = {
            renice = 10; # Nice game processes for better priority
            ioprio = 0; # Highest IO priority for game processes
            inhibit_screensaver = 1;
            disable_splitlock = 1; # Disable split-lock mitigation for performance
          };

          cpu = {
            park_cores = "no"; # Don't park cores
            pin_cores = "yes"; # Pin game to optimal cores (auto-detected)
          };

          gpu = {
            # AMD GPU optimization - switch to high performance level
            apply_gpu_optimisations = "accept-responsibility";
            gpu_device = cfg.gpuDevice;
            amd_performance_level = "high";
          };

          custom = {
            start = startScript.outPath;
            end = endScript.outPath;
          };
        };
      };

      # Add user to gamemode group for renice and parking permissions
      users.users.${config.khanelinix.user.name}.extraGroups = [ "gamemode" ];

      security.wrappers.gamemode = {
        owner = "root";
        group = "root";
        source = "${lib.getExe' pkgs.gamemode "gamemoderun"}";
        capabilities = "cap_sys_ptrace,cap_sys_nice+pie";
      };

      security.polkit.extraConfig = ''
        polkit.addRule(function(action, subject) {
          if ((action.id == "com.feralinteractive.GameMode.governor-helper" ||
               action.id == "com.feralinteractive.GameMode.procsys-helper" ||
               action.id == "com.feralinteractive.GameMode.gpu-helper") &&
              subject.isInGroup("users")) {
            return polkit.Result.YES;
          }
        });
      '';

      # Allow reading CPU power consumption for gamemode monitoring
      systemd.tmpfiles.settings."10-gamemode-powercap" = {
        "/sys/devices/virtual/powercap/intel-rapl/intel-rapl:0/intel-rapl:0:0/energy_uj".z = {
          mode = "0644";
        };
      };

      # <https://www.phoronix.com/news/Fedora-39-VM-Max-Map-Count>
      # <https://github.com/pop-os/default-settings/blob/master_jammy/etc/sysctl.d/10-pop-default-settings.conf>
      boot.kernel.sysctl = {
        # default on some gaming (SteamOS) and desktop (Fedora) distributions
        # might help with gaming performance
        "vm.max_map_count" = 2147483642;
      };

      environment.systemPackages = [
        (pkgs.writeShellScriptBin "gamemode-register" ''
          PID=$1
          if [ -z "$PID" ]; then
              PIDS=$(pgrep -af 'steam_.*game|proton|wine-preloader|wine64-preloader|lutris|heroic|gamemoderun' | awk '{print $1}')
              if [ -n "$PIDS" ]; then
                  PID=$(echo "$PIDS" | head -n 1)
                  echo "No PID provided. Auto-detected likely game PID: $PID"
              else
                  echo "Usage: gamemode-register <PID>"
                  echo "Could not auto-detect any running games."
                  exit 1
              fi
          fi
          ${lib.getExe' pkgs.systemd "busctl"} --user call com.feralinteractive.GameMode /com/feralinteractive/GameMode com.feralinteractive.GameMode RegisterGame i "$PID"
        '')
        (pkgs.writeShellScriptBin "gamemode-unregister" ''
          PID=$1
          if [ -z "$PID" ]; then
              PIDS=$(pgrep -af 'steam_.*game|proton|wine-preloader|wine64-preloader|lutris|heroic|gamemoderun' | awk '{print $1}')
              if [ -n "$PIDS" ]; then
                  PID=$(echo "$PIDS" | head -n 1)
                  echo "No PID provided. Auto-detected likely game PID: $PID"
              else
                  echo "Usage: gamemode-unregister <PID>"
                  echo "Could not auto-detect any running games."
                  exit 1
              fi
          fi
          ${lib.getExe' pkgs.systemd "busctl"} --user call com.feralinteractive.GameMode /com/feralinteractive/GameMode com.feralinteractive.GameMode UnregisterGame i "$PID"
        '')
      ];
    };
}
