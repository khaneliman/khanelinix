{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.programs.terminal.tools.atuin;
in
{
  options.${namespace}.programs.terminal.tools.atuin = {
    enable = lib.mkEnableOption "atuin";
    enableDebug = lib.mkEnableOption "atuin daemon debug logging";
  };

  config = mkIf cfg.enable {
    programs.atuin = {
      enable = true;

      enableBashIntegration = true;
      enableFishIntegration = true;
      enableZshIntegration = true;
      enableNushellIntegration = true;

      daemon =
        {
          enable = true;
        }
        // lib.optionalAttrs cfg.enableDebug {
          logLevel = "debug";
        };
    };
  };
}
