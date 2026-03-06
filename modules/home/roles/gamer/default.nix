{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.khanelinix) enabled;

  cfg = config.khanelinix.roles.gamer;
in
{
  options.khanelinix.roles.gamer = {
    enable = lib.mkEnableOption "gamer role";
  };

  config = mkIf cfg.enable {
    khanelinix.suites = {
      emulation = enabled;
      games = {
        enable = true;
        protonToolsEnable = true;
      };
    };
  };
}
