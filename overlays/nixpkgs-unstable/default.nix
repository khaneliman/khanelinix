{ inputs, mkPkgs, ... }:
final: prev: 
let
  unstable = mkPkgs inputs.nixpkgs-unstable final.system final.config;
in {
  inherit (unstable)
    # Core
    jankyborders
    nixVersions
    raycast
    # NOTE: Conflicts with sketchybar version overlay
    # sketchybar
    skhd
    yabai

    # Misc
    _1password-gui
    alt-tab-macos
    appcleaner
    bartender
    blueutil
    duti
    mas
    monitorcontrol
    stats
    switchaudio-osx

    # Online services to keep up to date
    element-desktop
    firefox-devedition
    firefox-devedition-unwrapped
    teams-for-linux
    telegram-desktop
    ;
}
