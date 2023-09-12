{ options
, config
, lib
, ...
}:
let
  inherit (lib) mkIf mkForce;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.archetypes.wsl;
in
{
  options.khanelinix.archetypes.wsl = {
    enable =
      mkBoolOpt false "Whether or not to enable the wsl archetype.";
  };

  config = mkIf cfg.enable {
    environment.noXlibs = mkForce false;

    khanelinix = { };
  };
}
