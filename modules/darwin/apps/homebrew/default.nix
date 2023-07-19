{
  options,
  config,
  lib,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.apps.homebrew;
in {
  options.khanelinix.apps.homebrew = with types; {
    enable = mkBoolOpt false "Whether or not to enable homebrew.";
  };

  config = mkIf cfg.enable {
    homebrew = {
      enable = true;

      global = {
        brewfile = true;
      };

      brews = [
        "fastfetch"
        "felixkratz/formulae/sketchybar"
        "fisher"
        "ical-buddy"
        "koekeishiya/formulae/skhd"
        "koekeishiya/formulae/yabai"
        "blueutil"
        "brew-cask-completion"
        "librsvg"
        "switchaudio-osx"
        "ifstat"
        "jq"
        "gh"
      ];

      taps = [
        "1password/tap"
        "arthurk/virt-manager"
        "beeftornado/rmtree"
        "bramstein/webfonttools"
        "cloudflare/cloudflare"
        "earthly/earthly"
        "felixkratz/formulae"
        "homebrew/bundle"
        "homebrew/cask"
        "homebrew/cask-fonts"
        "homebrew/cask-versions"
        "homebrew/core"
        "homebrew/services"
        "khanhas/tap"
        "koekeishiya/formulae"
        "romkatv/powerlevel10k"
        "shaunsingh/sfmono-nerd-font-ligaturized"
        "teamookla/speedtest"
      ];

      casks = [
        "1password"
        "1password-cli"
        "alacritty"
        "alfred"
        "alt-tab"
        "appcleaner"
        "authy"
        "bartender"
        "betterdiscord-installer"
        "bitwarden"
        "brightness"
        "caprine"
        "cutter"
        "discord"
        "docker"
        "electron"
        "firefox-developer-edition"
        "gpg-suite"
        "grammarly"
        "hammerspoon"
        "inkscape"
        "kitty"
        "libreoffice"
        "lulu"
        "meetingbar"
        "monitorcontrol"
        "moonlight"
        "obsidian"
        "powershell"
        "raycast"
        "sf-symbols"
        "skim"
        "sloth"
        "spotify"
        "stats"
        "thunderbird"
        "utm"
        "visual-studio-code"
        "xquartz"
        # "fork"
        # "hot"
        # "iina"
        # "jetbrains-toolbox"
        # "rancher"
        # "zotero"
      ];

      masApps = {
        "1Password for Safari" = 1569813296;
        "AdGuard for Safari" = 1440147259;
        "AmorphousMemoryMark" = 1495719766;
        "Amphetamine" = 937984704;
        "AutoMounter" = 1160435653;
        "Brother iPrint&Scan" = 1193539993;
        "Cascadea" = 1432182561;
        "Dark Reader for Safari" = 1438243180;
        "Disk Speed Test" = 425264550;
        "GarageBand" = 682658836;
        "iMovie" = 408981434;
        "Infuse" = 1136220934;
        "Keynote" = 409183694;
        "Malwarebytes Browser Guard" = 1577761052;
        "MediaInfo" = 510620098;
        "Messenger" = 1480068668;
        "Microsoft OneNote" = 784801555;
        "Microsoft Remote Desktop" = 1295203466;
        "Notability" = 360593530;
        "Numbers" = 409203825;
        "Pages" = 409201541;
        "Patterns" = 429449079;
        "Pixelmator" = 407963104;
        "PopClip" = 445189367;
        "Prime Video" = 545519333;
        "Slack" = 803453959;
        "Telegram" = 747648890;
        "TestFlight" = 899247664;
        "WiFi Explorer" = 494803304;
        "Xcode" = 497799835;
      };
    };
  };
}
