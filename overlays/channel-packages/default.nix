{ inputs }:
final: _prev:
let
  master = import inputs.nixpkgs-master {
    inherit (final.stdenv.hostPlatform) system;
    inherit (final) config;
  };
  unstable = import inputs.nixpkgs-unstable {
    inherit (final.stdenv.hostPlatform) system;
    inherit (final) config;
  };
in
{
  # From nixpkgs-master (fast updating / want latest always)
  inherit (master)
    claude-code
    yaziPlugins

    # TODO: remove after hits channel
    opencode
    ;

  # From nixpkgs-unstable
  inherit (unstable)
    # Misc
    _1password-gui

    # Online services to keep up to date
    element-desktop
    # FIXME: enable after gtk3 overlay removed
    # firefox-devedition
    firefox-devedition-unwrapped
    teams-for-linux
    telegram-desktop
    thunderbird-unwrapped
    # FIXME: enable after gtk3 overlay removed
    # thunderbird-latest
    ;
}
