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

    # TODO: remove once makes it to unstable
    ;

  sherlock-launcher = master.sherlock-launcher.overrideAttrs (oldAttrs: {
    nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
      final.wrapGAppsHook4
    ];
  });

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
