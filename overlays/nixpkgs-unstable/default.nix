{ channels, ... }:
_final: _prev: {
  inherit (channels.nixpkgs-unstable)
    # Core
    jankyborders
    raycast
    sketchybar
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

    # TODO: remove once in nixos-unstable
    firefox-devedition
    ;
}
