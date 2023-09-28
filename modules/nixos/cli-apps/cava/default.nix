{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.cli-apps.cava;
in
{
  options.khanelinix.cli-apps.cava = {
    enable = mkBoolOpt false "Whether or not to enable cava.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ cava ];

    khanelinix.home = {
      configFile = {
        "cava/config".source = ./config;
      };

      extraOptions.home.shellAliases = {
        cava = "TERM=st-256color cava";
      };
    };
  };
}
