{ inputs }:
final: prev:
let
  inherit (final.stdenv.hostPlatform) system;

  # master = import inputs.nixpkgs-master {
  #   inherit system;
  #   inherit (prev) config;
  # };

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

  #          ╭──────────────────────────────────────────────────────────╮
  #          │ From nixpkgs-master (fast updating / want latest always) │
  #          ╰──────────────────────────────────────────────────────────╯
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
}
