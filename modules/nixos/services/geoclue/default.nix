{ options
, config
, lib
, ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.internal) mkBoolOpt;
  cfg = config.khanelinix.services.geoclue;
in
{
  options.khanelinix.services.geoclue = with types; {
    enable = mkBoolOpt false "Whether or not to configure geoclue support.";
  };

  config = mkIf cfg.enable { services.geoclue2.enable = true; };
}
