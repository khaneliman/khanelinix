inputs @ { options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.cli-apps.hydra-check;
in
{
  options.khanelinix.cli-apps.hydra-check = with types; {
    enable = mkBoolOpt false "Whether or not to enable hydra-check.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      hydra-check
    ];
  };
}
