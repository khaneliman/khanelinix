{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) mkOpt;

  cfg = config.${namespace}.services.jankyborders;
in
{
  options.${namespace}.services.jankyborders = {
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
    logFile = mkOpt lib.types.str "${
      config.users.users.${config.${namespace}.user.name}.home
    }/Library/Logs/jankyborders.log" "Filepath of log output";
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
