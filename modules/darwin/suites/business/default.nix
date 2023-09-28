{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.suites.business;
in
{
  options.khanelinix.suites.business = {
    enable = mkBoolOpt false "Whether or not to enable business configuration.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      calcurse
      dooit
      jrnl
      nb
    ];

    homebrew = {
      taps = [
        "1password/tap"
      ];

      casks = [
        "1password"
        "1password-cli"
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
        "1Password for Safari" = 1569813296;
        "Brother iPrint&Scan" = 1193539993;
        "Keynote" = 409183694;
        "Microsoft OneNote" = 784801555;
        "Notability" = 360593530;
        "Numbers" = 409203825;
        "Pages" = 409201541;
      };
    };
  };
}
