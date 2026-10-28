{ inputs }:
final: prev:
let
  inherit (final.stdenv.hostPlatform) system;

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

  # TODO: remove after numtide/llm-agents.nix#11477 lands. fastmcp-slim is
  # marked broken against mcp 2, so build this Python scope against mcp 1.x.
  # The package calls `python3.override` itself, so compose with its
  # packageOverrides instead of replacing them.
  code-review-graph = inputs.llm-agents.packages.${system}.code-review-graph.override {
    python3 = final.python3 // {
      override =
        args:
        final.python3.override (
          args
          // {
            packageOverrides = final.lib.composeExtensions (pyFinal: _: {
              mcp = pyFinal.mcp_1;
            }) args.packageOverrides;
          }
        );
    };
  };

  # Darwin's sandbox crashes the binary's version check, although it runs
  # outside the sandbox. Keep Linux's install check enabled.
  opencode = inputs.llm-agents.packages.${system}.opencode.overrideAttrs (_old: {
    doInstallCheck = !final.stdenv.hostPlatform.isDarwin;
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

  github-copilot-cli = inputs.llm-agents.packages.${system}.copilot-cli.overrideAttrs (
    old:
    final.lib.optionalAttrs final.stdenv.hostPlatform.isDarwin {
      # The bundled Node binary probes a system OpenSSL file denied by the sandbox.
      preVersionCheck = (old.preVersionCheck or "") + ''
        export OPENSSL_CONF=/dev/null
      '';
      versionCheckKeepEnvironment = (old.versionCheckKeepEnvironment or [ ]) ++ [ "OPENSSL_CONF" ];
    }
  );
  pi-coding-agent = inputs.llm-agents.packages.${system}.pi;

  #          ╭──────────────────────────────────────────────────────────╮
  #          │                 Darwin package overrides                 │
  #          ╰──────────────────────────────────────────────────────────╯
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
