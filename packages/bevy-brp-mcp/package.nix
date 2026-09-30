{
  lib,
  cargo,
  fetchFromGitHub,
  makeWrapper,
  rustPlatform,
  rustc,
  ...
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "bevy_brp_mcp";
  version = "0.22.8";

  src = fetchFromGitHub {
    owner = "natepiano";
    repo = "bevy_brp";
    rev = "v${finalAttrs.version}";
    hash = "sha256-HsA4C41ao3I1eiVTZOcChv8KAY2gdSqVrUD7goJp8p8=";
  };

  patches = [
    ./progressive-tool-help.patch
  ];

  buildAndTestSubdir = "mcp";

  cargoHash = "sha256-BggAqEJ/rmzabLqlIN71l3FDHwrhzyEyhHJ64iqxyl8=";

  nativeBuildInputs = [
    makeWrapper
    rustPlatform.bindgenHook
  ];

  postFixup = ''
    wrapProgram $out/bin/bevy_brp_mcp \
      --suffix PATH : ${
        lib.makeBinPath [
          cargo
          rustc
        ]
      }
  '';

  doInstallCheck = true;

  installCheckPhase = ''
    runHook preInstallCheck

    response="$(
      printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"khanelinix-smoke","version":"0"}}}' \
        | "$out/bin/bevy_brp_mcp"
    )"
    grep -q '"protocolVersion":"2024-11-05"' <<< "$response"
    grep -q '"tools"' <<< "$response"

    runHook postInstallCheck
  '';

  meta = {
    description = "MCP server for Bevy Remote Protocol integration";
    homepage = "https://github.com/natepiano/bevy_brp";
    changelog = "https://github.com/natepiano/bevy_brp/blob/v${finalAttrs.version}/mcp/CHANGELOG.md";
    license = [
      lib.licenses.mit
      lib.licenses.asl20
    ];
    maintainers = [ lib.maintainers.khaneliman ];
    mainProgram = "bevy_brp_mcp";
    platforms = lib.platforms.unix;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
})
