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
            softrealtime = "auto";
            renice = 10;
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
    };
}
