{ inputs }:
final: _prev:
let
  inherit (final.stdenv.hostPlatform) system;
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
    workmux
    zat
    ;

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
  codex =
    (inputs.llm-agents.packages.${system}.codex.override (old: {
      # openssl-sys links aws-lc through its OpenSSL-compatible openssl.pc and
      # cannot bind prefixed symbols. nixpkgs now prefixes symbols and ships
      # the shim only on request. Drop this once llm-agents sets both itself.
      aws-lc = old.aws-lc.override {
        withOpenSSLShim = true;
        symbolPrefix = null;
      };
    })).overrideAttrs
      (old: {
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
}
