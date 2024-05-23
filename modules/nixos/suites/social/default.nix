{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt enabled;
  cfg = config.${namespace}.suites.social;
in
{
  options.${namespace}.suites.social = {
    enable = mkBoolOpt false "Whether or not to enable social configuration.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # armcord
      caprine-bin
      element-desktop
      slack
      telegram-desktop
    ];

    khanelinix = {
      programs = {
        graphical = {
          apps = {
            # TODO: switch to armcord ?
            discord = enabled;
          };
        };
      };
    };
  };
}
