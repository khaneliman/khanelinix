{
  buildGoModule,
  fetchFromGitHub,
  lib,
  ...
}:

buildGoModule (finalAttrs: {
  pname = "cliproxyapi";
  version = "7.2.149";

  src = fetchFromGitHub {
    owner = "router-for-me";
    repo = "CLIProxyAPI";
    tag = "v${finalAttrs.version}";
    hash = "sha256-B13kmOdTEOPv3Dl9DjuU0iwsTPa6XP1u/WLk3HaZz2o=";
  };

  vendorHash = "sha256-CrDp7MOr+AwJUhTovklXx3F1yaktQlvD7VYhYSY6VvY=";

  subPackages = [ "cmd/server" ];

  ldflags = [
    "-s"
    "-w"
    "-X main.Version=${finalAttrs.version}"
    "-X main.Commit=2a6b87a"
    "-X main.BuildDate=2026-09-03T13:27:23Z"
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
