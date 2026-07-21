{ inputs }:
final: prev:
let
  inherit (final.stdenv.hostPlatform) system;

  master = import inputs.nixpkgs-master {
    inherit system;
    inherit (prev) config;
  };

  useLldOnDarwin =
    package:
    if final.stdenv.hostPlatform.isDarwin then
      package.overrideAttrs (old: {
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.llvmPackages.lld ];
        env = (old.env or { }) // {
          NIX_CFLAGS_LINK = "-fuse-ld=lld";
        };
      })
    else
      package;

  # TODO: remove after NixOS/nixpkgs#540742 hits the channel
  patoolFile = prev.file.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace src/landlock.c --replace-fail \
        "LANDLOCK_ACCESS_FS_READ_FILE | LANDLOCK_ACCESS_FS_READ_DIR" \
        "LANDLOCK_ACCESS_FS_READ_FILE | LANDLOCK_ACCESS_FS_READ_DIR | LANDLOCK_ACCESS_FS_EXECUTE"
    '';
  });

  # TODO: remove after openai/codex#32312 reaches a stable llm-agents release.
  # Codex Desktop can persist UUID-only response item IDs. The Responses API
  # rejects those IDs during replay because they lack a resource prefix.
  codex = inputs.llm-agents.packages.${system}.codex.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      (builtins.toFile "codex-require-response-item-id-prefix.patch" ''
        diff --git a/core/src/client.rs b/core/src/client.rs
        --- a/core/src/client.rs
        +++ b/core/src/client.rs
        @@ -915,6 +915,16 @@ impl ModelClient {
             }

             fn prepare_response_items_for_request(&self, input: &mut [ResponseItem], store: bool) {
        +        for item in input.iter_mut() {
        +            if item.id().is_some_and(|id| {
        +                !id.split_once('_').is_some_and(|(prefix, suffix)| {
        +                    !prefix.is_empty() && !suffix.is_empty()
        +                })
        +            }) {
        +                item.set_id(/*new_id*/ None);
        +            }
        +        }
        +
                 if self.state.item_ids_enabled || store {
                     return;
                 }
      '')
    ];
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

  inherit codex;

  github-copilot-cli = inputs.llm-agents.packages.${system}.copilot-cli;
  pi-coding-agent = inputs.llm-agents.packages.${system}.pi;

  #          ╭──────────────────────────────────────────────────────────╮
  #          │ From nixpkgs-master (fast updating / want latest always) │
  #          ╰──────────────────────────────────────────────────────────╯
  # TODO: remove after the ld64 hardening workarounds reach the unstable channel.
  blueutil = if final.stdenv.hostPlatform.isDarwin then master.blueutil else prev.blueutil;
  darktable =
    if final.stdenv.hostPlatform.isDarwin then
      master.darktable.overrideAttrs {
        # `darktable --version` hangs indefinitely inside the Darwin build sandbox.
        # Compilation and linking finish before this smoke check runs.
        doInstallCheck = false;
      }
    else
      prev.darktable;
  godot = if final.stdenv.hostPlatform.isDarwin then master.godot else prev.godot;
  mpv-unwrapped =
    if final.stdenv.hostPlatform.isDarwin then master.mpv-unwrapped else prev.mpv-unwrapped;
  sketchybar = if final.stdenv.hostPlatform.isDarwin then master.sketchybar else prev.sketchybar;
  stats = if final.stdenv.hostPlatform.isDarwin then master.stats else prev.stats;
  terminal-notifier =
    if final.stdenv.hostPlatform.isDarwin then master.terminal-notifier else prev.terminal-notifier;

  #          ╭──────────────────────────────────────────────────────────╮
  #          │                 Darwin package overrides                 │
  #          ╰──────────────────────────────────────────────────────────╯
  # MLX distributes a CPython 3.13 Darwin wheel. Loading it through the
  # default Python 3.14 leaves mlx.core without its compiled attributes.
  exo =
    if final.stdenv.hostPlatform.isDarwin then
      prev.callPackage "${inputs.nixpkgs}/pkgs/by-name/ex/exo/package.nix" {
        python3Packages = final.python313Packages;
      }
    else
      prev.exo;

  # LM Studio's APFS disk image requires hdiutil, which cannot mount inside
  # Nix's Darwin sandbox. `sandbox = "relaxed"` honors this package opt-out.
  lmstudio = prev.lmstudio.overrideAttrs {
    __noChroot = final.stdenv.hostPlatform.isDarwin;
  };

  # TODO: remove after the ld64 hardening workaround reaches input-leap.
  input-leap = useLldOnDarwin prev.input-leap;

  # TODO: remove after the ld64 hardening workaround reaches musikcube.
  musikcube = useLldOnDarwin prev.musikcube;

  # TODO: remove after the ld64 hardening workaround reaches ncspot.
  ncspot = useLldOnDarwin prev.ncspot;

  # TODO: remove after the ld64 hardening workaround reaches moonlight-qt.
  moonlight-qt = useLldOnDarwin prev.moonlight-qt;

  # TODO: remove after the ld64 hardening workaround reaches mkvtoolnix.
  mkvtoolnix = useLldOnDarwin prev.mkvtoolnix;

  # TODO: remove after the ld64 hardening workaround reaches unar.
  unar = useLldOnDarwin prev.unar;

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
}
