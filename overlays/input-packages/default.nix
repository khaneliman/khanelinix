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
  codex =
    let
      package = inputs.llm-agents.packages.${system}.codex;
      # TODO: drop once llm-agents ships 0.159.0 (numtide/llm-agents.nix#10062).
      # OpenAI rejects gpt-6.1-sol from older clients signed in with ChatGPT.
      current =
        if final.lib.versionOlder package.version "0.159.0" then
          package.override {
            version = "0.159.0";
            hash = "sha256-rtYsWjG56SagT5cWt22//vyqvD0QBKSHRdRhzHQB4CQ=";
            cargoVendor.cargoHash = "sha256-3X4gmzAZG10DDcI667k9Zf+r3IvzeAAWD1NbTdQZyGY=";
          }
        else
          package;
    in
    current.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [
        ./codex-force-multi-agent-v1.patch
        ./codex-user-agent-provider.patch
        # openai/codex#49318 landed after 0.159.0; drop once a release has it.
        (final.fetchpatch2 {
          name = "codex-gpt-6.1-sol-catalog.patch";
          url = "https://github.com/openai/codex/commit/b1e72963c3b71a9265a551e54beff078384efed9.patch?full_index=1";
          relative = "codex-rs";
          includes = [ "models-manager/models.json" ];
          hash = "sha256-K2lIihDEkcItKhOLJGntLYLqzuSIXcov0DOM4dO1+sQ=";
        })
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
