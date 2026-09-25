{
  buildGoModule,
  fetchFromGitHub,
  lib,
  stdenv,
  ...
}:

buildGoModule (finalAttrs: {
  pname = "cliproxyapi";
  version = "7.3.12-1";

  src = fetchFromGitHub {
    owner = "kaitranntt";
    repo = "CLIProxyAPIPlus";
    tag = "v${finalAttrs.version}";
    hash = "sha256-ux5WhKCApQDcxcnDsKGoBNy5dnTHinNxC8Jdh5rU0JI=";
  };

  # Agent SDK requests must not inherit the proxy's older CLI version.
  patches = [ ./agent-sdk-client-version.patch ];

  vendorHash = "sha256-P+0dbN+eKoOSBpJfo4hq86ZbWKUel+5biCBGgePm88k=";

  subPackages = [ "cmd/server" ];

  ldflags = [
    "-s"
    "-w"
    "-X main.Version=${finalAttrs.version}"
    "-X main.Commit=04048d8"
    "-X main.BuildDate=2026-09-23T00:18:15Z"
  ];

  preCheck = ''
    ${lib.optionalString stdenv.hostPlatform.isDarwin ''
      go test -run '^TestClaudeRequestVersion$' ./internal/runtime/executor/helps
      go test -run '^$' ./internal/auth/copilot ./internal/runtime/executor
    ''}
    ${lib.optionalString (!stdenv.hostPlatform.isDarwin) ''
      go test ./internal/auth/copilot ./internal/runtime/executor/helps ./internal/runtime/executor
    ''}
  '';

  postInstall = ''
    mv "$out/bin/server" "$out/bin/cli-proxy-api"
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    "$out/bin/cli-proxy-api" --help >/dev/null

    runHook postInstallCheck
  '';

  meta = {
    description = "OpenAI, Gemini, Claude, and Codex compatible proxy with GitHub Copilot support";
    homepage = "https://github.com/kaitranntt/CLIProxyAPIPlus";
    changelog = "https://github.com/kaitranntt/CLIProxyAPIPlus/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    maintainers = [ lib.maintainers.khaneliman ];
    mainProgram = "cli-proxy-api";
    platforms = lib.platforms.unix;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
})
