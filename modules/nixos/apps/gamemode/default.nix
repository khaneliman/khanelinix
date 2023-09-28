{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) types mkIf getExe';
  inherit (lib.internal) mkBoolOpt mkOpt;

  cfg = config.khanelinix.apps.gamemode;
  # programs = lib.makeBinPath [config.khanelinix.desktop.hyprland.package];

  defaultStartScript = ''
    ${getExe' pkgs.libnotify "notify-send"} 'GameMode started'
  '';

  defaultEndScript = ''
    ${getExe' pkgs.libnotify "notify-send"} 'GameMode ended'
  '';
in
{
  options.khanelinix.apps.gamemode = with types; {
    enable = mkBoolOpt false "Whether or not to enable gamemode.";
    endscript = mkOpt (nullOr str) null "The script to run when disabling gamemode.";
    startscript = mkOpt (nullOr str) null "The script to run when enabling gamemode.";
  };

  config =
    let
      startScript =
        if (cfg.startscript == null)
        then pkgs.writeShellScript "gamemode-start" defaultStartScript
        else pkgs.writeShellScript "gamemode-start" cfg.startscript;
      endScript =
        if (cfg.endscript == null)
        then pkgs.writeShellScript "gamemode-end" defaultEndScript
        else pkgs.writeShellScript "gamemode-end" cfg.endscript;
    in
    mkIf cfg.enable
      {
        programs.gamemode = {
          enable = true;
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
      };
}
