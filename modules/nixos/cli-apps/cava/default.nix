{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.cli-apps.cava;
in
{
  options.khanelinix.cli-apps.cava = with types; {
    enable = mkBoolOpt false "Whether or not to enable cava.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ cava ];

    khanelinix.home = {
      configFile = {
        "cava/config".source = ./config;
      };
    };
  };
}
