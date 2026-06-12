{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkDefault mkIf;

  cfg = config.khanelinix.roles.gamer;
in
{
  options.khanelinix.roles.gamer = {
    enable = lib.mkEnableOption "gamer role";
  };

  config = mkIf cfg.enable {
    khanelinix.suites = {
      emulation.enable = mkDefault true;
      games = {
        enable = true;
        protonToolsEnable = true;
      };
    };
  };
}
