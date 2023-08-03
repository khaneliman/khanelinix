{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.suites.business;
in
{
  options.khanelinix.suites.business = with types; {
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

      masApps = {
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
