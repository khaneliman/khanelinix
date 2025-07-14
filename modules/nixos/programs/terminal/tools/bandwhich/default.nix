{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.terminal.tools.bandwhich;
in
{
  options.khanelinix.programs.terminal.tools.bandwhich = {
    enable = lib.mkEnableOption "bandwhich";
  };

  config = mkIf cfg.enable {
    programs.bandwhich = {
      enable = true;
    };
  };
}
