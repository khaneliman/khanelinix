{ inputs }:
final: prev:
let
  inherit (final.stdenv.hostPlatform) system;

  master = import inputs.nixpkgs-master {
    inherit system;
    inherit (prev) config;
  };

  unstable = import inputs.nixpkgs-unstable {
    inherit system;
    inherit (prev) config;
  };
in
{
  #          ╭──────────────────────────────────────────────────────────╮
  #          │                       LLM programs                       │
  #          ╰──────────────────────────────────────────────────────────╯
  inherit (inputs.llm-agents.packages.${system})
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
    libreoffice
    ;

  #          ╭──────────────────────────────────────────────────────────╮
  #          │                 Python package overrides                 │
  #          ╰──────────────────────────────────────────────────────────╯
  # Keep this disabled unless we need explicit python package overrides.
  # python3 = _prev.python3.override {
  #   packageOverrides = _pyFinal: _pyPrev: {
  #     # TODO: remove after hitting channel
  #   };
  # };
  # python3Packages = final.python3.pkgs;

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
    telegram-desktop
    thunderbird-unwrapped
    thunderbird-latest
    ;

  teams-for-linux = unstable.teams-for-linux.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace app/customCSS/index.js \
        --replace-fail "style.innerHTML = " "style.textContent = "
    '';
  });

  #          ╭──────────────────────────────────────────────────────────╮
  #          │   Override linuxKernel.packages.linux_zen specifically   │
  #          ╰──────────────────────────────────────────────────────────╯
  # linuxKernel = _prev.linuxKernel // {
  #   packages = _prev.linuxKernel.packages // {
  #     inherit (unstable.linuxKernel.packages) linux_zen;
  #   };
  # };
}
