{
  config,
  lib,
  khanelinix-lib,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (khanelinix-lib) mkBoolOpt;

  cfg = config.khanelinix.programs.terminal.tools.carapace;
in
{
  options.khanelinix.programs.terminal.tools.carapace = {
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
