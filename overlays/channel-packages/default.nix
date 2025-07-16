{ inputs }:
final: _prev:
let
  master = import inputs.nixpkgs-master {
    inherit (final) system config;
  };
  unstable = import inputs.nixpkgs-unstable {
    inherit (final) system config;
  };
in
{
  # From nixpkgs-master (fast updating / want latest always)
  inherit (master)
    claude-code
    yaziPlugins
    teams-for-linux # TODO: remove when hits unstable
    ;

  # From nixpkgs-unstable
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
    # TODO: enable when hits unstable
    # teams-for-linux
    telegram-desktop
    ;
}