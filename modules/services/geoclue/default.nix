{ options
, config
, pkgs
, lib
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.services.geoclue;
in
{
  options.khanelinix.services.geoclue = with types; {
    enable = mkBoolOpt false "Whether or not to configure geoclue support.";
  };

  config = mkIf cfg.enable { services.geoclue2.enable = true; };
}
