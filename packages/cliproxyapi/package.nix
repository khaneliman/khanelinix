{
  buildGoModule,
  fetchFromGitHub,
  lib,
  ...
}:

buildGoModule (finalAttrs: {
  pname = "cliproxyapi";
  version = "7.2.94";

  src = fetchFromGitHub {
    owner = "router-for-me";
    repo = "CLIProxyAPI";
    tag = "v${finalAttrs.version}";
    hash = "sha256-f0aBi/Pz+Dyd3X1V0qVg71GSxTKli1WbWI45e2dWRK4=";
  };

  vendorHash = "sha256-xirNOpnPVwe/TqEYkHHLMWREajosaisBazvy8rFEIak=";

  subPackages = [ "cmd/server" ];

  ldflags = [
    "-s"
    "-w"
    "-X main.Version=${finalAttrs.version}"
    "-X main.Commit=36b45d5"
    "-X main.BuildDate=2026-07-21T19:30:32Z"
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
