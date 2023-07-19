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
        "Messenger" = 1480068668;
      };
    };
  };
}
