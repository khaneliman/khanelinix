{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.programs.terminal.tools.atuin;
in
{
  options.${namespace}.programs.terminal.tools.atuin = {
    enable = mkBoolOpt false "Whether or not to enable atuin.";
    enableDebug = mkBoolOpt false "Whether or not to enable atuin daemon debug logging.";
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
