{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.roles.gamer;
in
{
  options.khanelinix.roles.gamer = {
    enable = lib.mkEnableOption "gamer role";
  };

  config = mkIf cfg.enable {
    khanelinix.suites = lib.khanelinix.nested-default-attrs {
      emulation.enable = true;
      games = {
        enable = true;
        protonToolsEnable = true;
      };
    };
  };
}
