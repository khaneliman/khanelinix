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
  #          ╭──────────────────────────────────────────────────────────╮
  #          │                 Firefox Addon repository                 │
  #          ╰──────────────────────────────────────────────────────────╯
  firefox-addons = import inputs.firefox-addons {
    inherit (final) fetchurl;
    inherit (final) lib;
    inherit (final) stdenv;
  };

  #          ╭──────────────────────────────────────────────────────────╮
  #          │ From nixpkgs-master (fast updating / want latest always) │
  #          ╰──────────────────────────────────────────────────────────╯
  inherit (master)
    claude-code
    codex
    gemini-cli
    opencode
    yazi-unwrapped
    yaziPlugins

    # TODO: remove after hitting channel
    ;

  python3 = _prev.python3.override {
    packageOverrides = _pyFinal: _pyPrev: {
      # TODO: remove after hitting channel
    };
  };

  python3Packages = final.python3.pkgs;

  #          ╭──────────────────────────────────────────────────────────╮
  #          │   From nixpkgs-unstable (reasonable update / stability   │
  #          │                         balance)                         │
  #          ╰──────────────────────────────────────────────────────────╯
  inherit (unstable)
    # Misc
    _1password-gui

    # Online services to keep up to date
    element-desktop
    firefox-devedition
    firefox-devedition-unwrapped
    teams-for-linux
    telegram-desktop
    thunderbird-unwrapped
    thunderbird-latest
    ;

  # Override linuxKernel.packages.linux_zen specifically
  linuxKernel = _prev.linuxKernel // {
    packages = _prev.linuxKernel.packages // {
      # inherit (unstable.linuxKernel.packages) linux_zen;
    };
  };
}
