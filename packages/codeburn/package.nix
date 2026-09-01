{
  buildNpmPackage,
  fetchFromGitHub,
  lib,
  makeWrapper,
  nodejs,
  ...
}:

buildNpmPackage rec {
  pname = "codeburn";
  version = "0.9.23";

  src = fetchFromGitHub {
    owner = "getagentseal";
    repo = "codeburn";
    tag = "v${version}";
    hash = "sha256-tM2lpVvfcVDqJbuSi0IRn3vtMqou7psjeSEOaQrDf3U=";
  };

  npmDepsHash = "sha256-22FANlY5IyBr7zISNC1Lz2FmFqHuAxTKyT1WcVGkwmQ=";

  nativeBuildInputs = [ makeWrapper ];

  buildPhase = ''
    runHook preBuild

    npx tsup
    node -e "const fs=require('fs'); fs.copyFileSync('src/cli.ts','dist/cli.js'); fs.chmodSync('dist/cli.js',0o755)"

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -d $out/lib/codeburn $out/bin
    cp -r dist package.json node_modules $out/lib/codeburn/

    makeWrapper ${lib.getExe nodejs} $out/bin/codeburn \
      --add-flags $out/lib/codeburn/dist/cli.js

    runHook postInstall
  '';

  meta = {
    description = "AI coding agent for terminal workflows";
    homepage = "https://github.com/getagentseal/codeburn";
    changelog = "https://github.com/getagentseal/codeburn/releases/tag/v${version}";
    license = lib.licenses.mit;
    mainProgram = "codeburn";
    platforms = lib.platforms.unix;
  };
}
