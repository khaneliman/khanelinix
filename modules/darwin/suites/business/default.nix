{ config, lib, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt enabled;

  cfg = config.khanelinix.suites.business;
in
{
  options.khanelinix.suites.business = {
    enable = mkBoolOpt false "Whether or not to enable business configuration.";
  };

  config = mkIf cfg.enable {
    homebrew = {
      casks = [
        "authy"
        "bitwarden"
        "calibre"
        "grammarly"
        "libreoffice"
        "meetingbar"
        "obsidian"
        "thunderbird"
      ];

      masApps = mkIf config.khanelinix.tools.homebrew.masEnable {
        "Brother iPrint&Scan" = 1193539993;
        "Keynote" = 409183694;
        "Microsoft OneNote" = 784801555;
        "Notability" = 360593530;
        "Numbers" = 409203825;
        "Pages" = 409201541;
      };
    };

    khanelinix = {
      programs = {
        graphical = {
          apps = {
            _1password = enabled;
          };
        };
      };
    };
  };
}
