{
  buildGoModule,
  fetchFromGitHub,
  lib,
  ...
}:

buildGoModule (finalAttrs: {
  pname = "cliproxyapi";
  version = "7.3.13";

  src = fetchFromGitHub {
    owner = "router-for-me";
    repo = "CLIProxyAPI";
    tag = "v${finalAttrs.version}";
    hash = "sha256-9ZiYPBEoxTcZaomY0Be4Q5hwQf5FCfdbvcJzYEGI+So=";
  };

  vendorHash = "sha256-r3yWkdMcM40G9jV7MxW/qNv3E9WrHavFilW24quEf+8=";

  subPackages = [ "cmd/server" ];

  ldflags = [
    "-s"
    "-w"
    "-X main.Version=${finalAttrs.version}"
    "-X main.Commit=2430354"
    "-X main.BuildDate=2026-09-22T18:41:31Z"
  ];

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
    description = "OpenAI, Gemini, Claude, and Codex compatible proxy for CLI models";
    homepage = "https://github.com/router-for-me/CLIProxyAPI";
    changelog = "https://github.com/router-for-me/CLIProxyAPI/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    maintainers = [ lib.maintainers.khaneliman ];
    mainProgram = "cli-proxy-api";
    platforms = lib.platforms.unix;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
})
