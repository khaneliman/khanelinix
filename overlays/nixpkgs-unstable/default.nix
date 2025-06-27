{ channels, ... }:
_final: _prev: {
  inherit (channels.nixpkgs-unstable)
    # Core
    jankyborders
    raycast
    # NOTE: Conflicts with sketchybar version overlay
    # sketchybar
    skhd
    yabai

    # Misc
    alt-tab-macos
    appcleaner
    bartender
    blueutil
    duti
    mas
    monitorcontrol
    stats
    switchaudio-osx

    nixVersions
    firefox-devedition-unwrapped
    firefox-devedition
    ;
}
