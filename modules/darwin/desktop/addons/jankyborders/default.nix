{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) mkOpt;

  cfg = config.${namespace}.desktop.addons.jankyborders;
in
{
  options.${namespace}.desktop.addons.jankyborders = {
    enable =
      lib.${namespace}.mkBoolOpt false
        "Whether to enable jankyborders in the desktop environment.";
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.jankyborders;
      defaultText = lib.literalExpression "pkgs.jankyborders";
      description = "The jankyborders package to use.";
      example = lib.literalExpression "pkgs.${namespace}.jankyborders";
    };
    logFile =
      mkOpt lib.types.str "/Users/khaneliman/Library/Logs/jankyborders.log"
        "Filepath of log output";
  };

  config = lib.mkIf cfg.enable {
    launchd.user.agents.jankyborders.serviceConfig = {
      StandardErrorPath = cfg.logFile;
      StandardOutPath = cfg.logFile;
      KeepAlive = lib.mkForce {
        PathState = {
          "/run/current-system/sw/bin/borders" = true;
        };
      };
    };

    services.jankyborders = {
      enable = true;

      style = "round";
      width = 6.0;
      hidpi = false;
      active_color = "0xff7793d1";
      inactive_color = "0xff5e6798";
      background_color = "0x302c2e34";
      blur_radius = 25.0;
    };
  };
}
