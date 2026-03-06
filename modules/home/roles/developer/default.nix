{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.khanelinix) enabled;

  cfg = config.khanelinix.roles.developer;
in
{
  options.khanelinix.roles.developer = {
    enable = lib.mkEnableOption "developer role";
  };

  config = mkIf cfg.enable {
    khanelinix.suites = {
      development = {
        enable = true;
        aiEnable = true;
        nixEnable = true;
      };
      networking = enabled;
    };
  };
}
