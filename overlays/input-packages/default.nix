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

  # FIXME: shouldn't have to do this
  buildMozillaXpiAddon = final.lib.makeOverridable (
    {
      pname,
      version,
      addonId,
      url ? "",
      urls ? [ ],
      sha256,
      meta,
      ...
    }:
    final.stdenv.mkDerivation {
      name = "${pname}-${version}";
      inherit meta;
      src = final.fetchurl { inherit url urls sha256; };
      preferLocalBuild = true;
      allowSubstitutes = true;
      passthru = { inherit addonId; };
      buildCommand = ''
        dst="$out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}"
        mkdir -p "$dst"
        install -v -m644 "$src" "$dst/${addonId}.xpi"
      '';
    }
  );
in
{
  #          ╭──────────────────────────────────────────────────────────╮
  #          │                 Firefox Addon repository                 │
  #          ╰──────────────────────────────────────────────────────────╯
  firefox-addons = import inputs.firefox-addons {
    inherit buildMozillaXpiAddon;
    inherit (final) fetchurl lib stdenv;
  };

  #          ╭──────────────────────────────────────────────────────────╮
  #          │                       LLM programs                       │
  #          ╰──────────────────────────────────────────────────────────╯
  inherit (inputs.llm-agents.packages.${final.stdenv.hostPlatform.system})
    claude-code
    codex
    opencode
    gemini-cli
    tuicr
    ;

  #          ╭──────────────────────────────────────────────────────────╮
  #          │ From nixpkgs-master (fast updating / want latest always) │
  #          ╰──────────────────────────────────────────────────────────╯
  inherit (master)
    yazi-unwrapped
    yaziPlugins

    # TODO: remove after hitting channel
    ;

  #          ╭──────────────────────────────────────────────────────────╮
  #          │                 Python package overrides                 │
  #          ╰──────────────────────────────────────────────────────────╯
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
    # element-desktop
    firefox-devedition
    firefox-devedition-unwrapped
    teams-for-linux
    telegram-desktop
    thunderbird-unwrapped
    thunderbird-latest
    ;

  #          ╭──────────────────────────────────────────────────────────╮
  #          │   Override linuxKernel.packages.linux_zen specifically   │
  #          ╰──────────────────────────────────────────────────────────╯
  linuxKernel = _prev.linuxKernel // {
    packages = _prev.linuxKernel.packages // {
      # inherit (unstable.linuxKernel.packages) linux_zen;
    };
  };
}
