{ flake }:
_self: super: {
  inherit (flake.inputs.nixpkgs-unstable.legacyPackages.${super.stdenv.system})
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

    ruff
    ;
}
