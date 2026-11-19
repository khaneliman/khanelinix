{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.roles.developer;
in
{
  options.khanelinix.roles.developer = {
    enable = lib.mkEnableOption "developer role";
  };

  config = mkIf cfg.enable {
    khanelinix.suites = lib.khanelinix.nested-default-attrs {
      development = {
        enable = true;
        aiEnable = true;
        nixEnable = true;
      };
      networking.enable = true;
    };
  };
}
