{ options
, config
, lib
, pkgs
, inputs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.apps.agenix;
in
{
  options.khanelinix.apps.agenix = with types; {
    enable = mkBoolOpt false "Whether or not to enable agenix.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with inputs; [
      agenix.packages.${pkgs.hostPlatform.system}.default
    ];
  };
}
