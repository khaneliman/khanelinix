{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.programs.terminal.tools.carapace;
in
{
  options.${namespace}.programs.terminal.tools.carapace = {
    enable = mkBoolOpt false "Whether or not to enable carapace.";
  };

  config = mkIf cfg.enable {
    programs.carapace = {
      enable = true;

      enableBashIntegration = true;
      enableFishIntegration = true;
      enableZshIntegration = true;
      enableNushellIntegration = true;
    };
  };
}
