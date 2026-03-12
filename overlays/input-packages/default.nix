{ inputs }:
final: prev:
let
  inherit (final.stdenv.hostPlatform) system;

  master = import inputs.nixpkgs-master {
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
    # yazi-unwrapped
    yaziPlugins

    # TODO: remove after hitting channel
    ;

  # TODO: remove after next release
  yazi-unwrapped = master.yazi-unwrapped.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      oldPattern=$'"--relative",\n\t\t\t\t"off",'
      newPattern=$'"--relative",\n\t\t\t\t"off",\n\t\t\t\t"--probe",\n\t\t\t\t"off",'
      substituteInPlace yazi-adapter/src/drivers/chafa.rs \
        --replace-fail \
        "$oldPattern" \
        "$newPattern"
    '';
  });

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
  #          │   Override linuxKernel.packages.linux_zen specifically   │
  #          ╰──────────────────────────────────────────────────────────╯
  # linuxKernel = _prev.linuxKernel // {
  #   packages = _prev.linuxKernel.packages // {
  #     inherit (unstable.linuxKernel.packages) linux_zen;
  #   };
  # };
}
