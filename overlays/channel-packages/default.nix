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
    ;

  # From nixpkgs-unstable
  inherit (unstable)
    # Misc
    _1password-gui

    # Online services to keep up to date
    element-desktop
    firefox-devedition
    firefox-devedition-unwrapped
    teams-for-linux
    telegram-desktop
    ;
}
