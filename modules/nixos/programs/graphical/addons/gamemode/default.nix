{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) types mkIf getExe';
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.programs.graphical.addons.gamemode;

  defaultStartScript = ''
    ${getExe' pkgs.libnotify "notify-send"} 'GameMode started'
  '';

  defaultEndScript = ''
    ${getExe' pkgs.libnotify "notify-send"} 'GameMode ended'
  '';
in
{
  options.${namespace}.programs.graphical.addons.gamemode = with types; {
    enable = mkBoolOpt false "Whether or not to enable gamemode.";
    endscript = mkOpt (nullOr str) null "The script to run when disabling gamemode.";
    startscript = mkOpt (nullOr str) null "The script to run when enabling gamemode.";
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
    mkIf cfg.enable {
      programs.gamemode = {
        enable = true;
        enableRenice = true;

        settings = {
          general = {
            softrealtime = "auto";
            renice = 15;
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
        source = "${getExe' pkgs.gamemode "gamemoderun"}";
        capabilities = "cap_sys_ptrace,cap_sys_nice+pie";
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
