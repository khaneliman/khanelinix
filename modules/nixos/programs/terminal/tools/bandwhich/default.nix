{
  config,
  lib,
  khanelinix-lib,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (khanelinix-lib) mkBoolOpt;

  cfg = config.khanelinix.programs.terminal.tools.bandwhich;
in
{
  options.khanelinix.programs.terminal.tools.bandwhich = {
    enable = mkBoolOpt false "Whether or not to enable bandwhich.";
  };

  config = mkIf cfg.enable {
    programs.bandwhich = {
      enable = true;
    };
  };
}
