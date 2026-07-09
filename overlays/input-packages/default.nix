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
    agentsview
    antigravity-cli
    ccusage
    ck
    claude-code
    claude-desktop
    code-review-graph
    codex
    git-surgeon
    hunk
    opencode
    rtk
    semble
    toon
    tuicr
    vibe-kanban
    workmux
    zat
    ;

  github-copilot-cli = inputs.llm-agents.packages.${system}.copilot-cli;
  pi-coding-agent = inputs.llm-agents.packages.${system}.pi;
  codex-desktop = inputs.codex-desktop-linux.packages.${system}.codex-desktop;

  #          ╭──────────────────────────────────────────────────────────╮
  #          │ From nixpkgs-master (fast updating / want latest always) │
  #          ╰──────────────────────────────────────────────────────────╯
  # inherit (master)
  #   # TODO: remove after hitting channel
  #   ;
  #          ╭──────────────────────────────────────────────────────────╮
  #          │                 Python package overrides                 │
  #          ╰──────────────────────────────────────────────────────────╯
  # Keep this disabled unless we need explicit python package overrides.
  python3 = prev.python3.override {
    packageOverrides = _pyFinal: _pyPrev: {
      # TODO: remove after hitting channel
    };
  };
  python3Packages = final.python3.pkgs;

  #          ╭──────────────────────────────────────────────────────────╮
  #          │   Override linuxKernel.packages.linux_zen specifically   │
  #          ╰──────────────────────────────────────────────────────────╯
  # linux-zen 7.0.12 in the channel installs $out/vmlinuz instead of
  # $out/bzImage, so the bootloader sanity check fails. master's 7.1.2 build
  # restores $out/bzImage; pull it until the fix reaches the unstable channel.
  # TODO: remove after hitting channel
  inherit (master) linuxPackages_zen;
}
