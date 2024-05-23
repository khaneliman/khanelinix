{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.services.geoclue;
in
{
  options.${namespace}.services.geoclue = {
    enable = mkBoolOpt false "Whether or not to configure geoclue support.";
  };

  config = mkIf cfg.enable { services.geoclue2.enable = true; };
}
