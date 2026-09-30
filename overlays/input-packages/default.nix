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
    code-review-graph
    git-surgeon
    hunk
    rtk
    semble
    toon
    tuicr
    vibe-kanban
    workmux
    zat
    ;

  # TODO: re-enable after the 1.18.18 binary stops crashing `--version` inside
  # the Darwin sandbox (passes outside it, so the artifact itself is fine).
  opencode = inputs.llm-agents.packages.${system}.opencode.overrideAttrs (_old: {
    doInstallCheck = false;
  });

  # Treat an enabled V1 feature with V2 disabled as an explicit protocol
  # choice. Otherwise Sol's model-catalog metadata silently promotes sessions
  # back to V2 and sends encrypted child prompts through the OAuth gateway.
  #
  # User-owned agent files may select configured providers. Project agents
  # retain the parent provider and authority boundary.
  codex = inputs.llm-agents.packages.${system}.codex.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      ./codex-force-multi-agent-v1.patch
      ./codex-user-agent-provider.patch
    ];
  });

  claude-desktop =
    let
      package = inputs.llm-agents.packages.${system}.claude-desktop;
    in
    # Chromium cannot infer Secret Service from wlroots desktop names and falls
    # back to plaintext basic_text storage despite an unlocked GNOME Keyring.
    if final.stdenv.hostPlatform.isLinux then
      package.override { commandLineArgs = "--password-store=gnome-libsecret"; }
    else
      package;

  github-copilot-cli = inputs.llm-agents.packages.${system}.copilot-cli;
  pi-coding-agent = inputs.llm-agents.packages.${system}.pi;

  #          ╭──────────────────────────────────────────────────────────╮
  #          │ From nixpkgs-master (fast updating / want latest always) │
  #          ╰──────────────────────────────────────────────────────────╯
  #          ╭──────────────────────────────────────────────────────────╮
  #          │                 Darwin package overrides                 │
  #          ╰──────────────────────────────────────────────────────────╯
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

}
