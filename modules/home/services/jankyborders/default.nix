{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib.khanelinix) mkOpt;

  cfg = config.khanelinix.services.jankyborders;
in
{
  options.khanelinix.services.jankyborders = {
    enable = lib.khanelinix.mkBoolOpt false "Whether to enable jankyborders in the desktop environment.";
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.jankyborders;
      defaultText = lib.literalExpression "pkgs.jankyborders";
      description = "The jankyborders package to use.";
      example = lib.literalExpression "pkgs.khanelinix.jankyborders";
    };
    logFile =
      mkOpt lib.types.str "${config.khanelinix.user.home}/Library/Logs/jankyborders.log"
        "Filepath of log output";
  };

  config = lib.mkIf cfg.enable {
    services.jankyborders = {
      enable = true;

      settings = {
        style = "round";
        width = 6.0;
        hidpi = "off";
        active_color = "0xff7793d1";
        inactive_color = "0xff5e6798";
        background_color = "0x302c2e34";
      };
    };
  };
}
