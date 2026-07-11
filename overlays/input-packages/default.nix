{ inputs }:
final: prev:
let
  inherit (final.stdenv.hostPlatform) system;

  master = import inputs.nixpkgs-master {
    inherit system;
    inherit (prev) config;
  };

  # TODO: remove after NixOS/nixpkgs#540742 hits the channel
  patoolFile = prev.file.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace src/landlock.c --replace-fail \
        "LANDLOCK_ACCESS_FS_READ_FILE | LANDLOCK_ACCESS_FS_READ_DIR" \
        "LANDLOCK_ACCESS_FS_READ_FILE | LANDLOCK_ACCESS_FS_READ_DIR | LANDLOCK_ACCESS_FS_EXECUTE"
    '';
  });
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
    # codex
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

  # Codex spawns a separate `codex-code-mode-host` binary to run shell and
  # file-edit commands, and looks for it next to its own executable.
  # llm-agents.nix only builds the `codex-cli` package, so the host binary is
  # missing from the store path and no shell or file-edit command can start.
  # Build it as well so it is installed alongside `codex` in `bin/`. Drop this
  # once https://github.com/numtide/llm-agents.nix/pull/6631 lands and the
  # input is bumped past it.
  codex = inputs.llm-agents.packages.${system}.codex.overrideAttrs (old: {
    cargoBuildFlags = (old.cargoBuildFlags or [ ]) ++ [
      "--package"
      "codex-code-mode-host"
    ];
  });

  github-copilot-cli = inputs.llm-agents.packages.${system}.copilot-cli;
  pi-coding-agent = inputs.llm-agents.packages.${system}.pi;

  #          ╭──────────────────────────────────────────────────────────╮
  #          │ From nixpkgs-master (fast updating / want latest always) │
  #          ╰──────────────────────────────────────────────────────────╯
  # inherit (master)
  #   # TODO: remove after hitting channel
  #   ;
  #          ╭──────────────────────────────────────────────────────────╮
  #          │                 Python package overrides                 │
  #          ╰──────────────────────────────────────────────────────────╯
  # Keep packageOverrides empty unless we need explicit Python package overrides.
  python3 = prev.python3.override {
    packageOverrides = _pyFinal: pyPrev: {
      # TODO: remove after NixOS/nixpkgs#540569 hits the channel
      catppuccin = pyPrev.catppuccin.overridePythonAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          (prev.fetchpatch2 {
            name = "catppuccin-matplotlib-3.11.patch";
            url = "https://github.com/catppuccin/python/commit/11ab7be947064f11453f1063f63455b343b7253d.patch";
            hash = "sha256-cYQBnGs1BRY/EOew/t5GAVZy2xEXLg8WMeSHiuGbd0U=";
          })
        ];
      });

      # TODO: remove after NixOS/nixpkgs#539806 hits the channel
      click-threading = pyPrev.click-threading.overridePythonAttrs (_old: {
        preCheck = ''
          rm -rf docs
        '';
      });

      patool = pyPrev.patool.override { file = patoolFile; };
    };
  };
  python3Packages = final.python3.pkgs;

  # TODO: remove after NixOS/nixpkgs#540569 hits the channel
  catppuccin-gtk = (prev.catppuccin-gtk.override { inherit (final) python3; }).overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      (prev.fetchpatch2 {
        name = "catppuccin-gtk-python-3.14.patch";
        url = "https://raw.githubusercontent.com/NixOS/nixpkgs/894acc94f63aae4b9483cf5d9f64c183398e2454/pkgs/by-name/ca/catppuccin-gtk/python-3.14.patch";
        hash = "sha256-onepzruX2DNH6WTrfDBj8O0Qd1VZ+IfQ5tsSqxa5aK0=";
      })
    ];
  });

  #          ╭──────────────────────────────────────────────────────────╮
  #          │   Override linuxKernel.packages.linux_zen specifically   │
  #          ╰──────────────────────────────────────────────────────────╯
  # linux-zen 7.0.12 in the channel installs $out/vmlinuz instead of
  # $out/bzImage, so the bootloader sanity check fails. master's 7.1.2 build
  # restores $out/bzImage; pull it until the fix reaches the unstable channel.
  # TODO: remove after hitting channel
  inherit (master) linuxPackages_zen;
}
