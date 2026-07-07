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
  version = "0.9.15";

  src = fetchFromGitHub {
    owner = "getagentseal";
    repo = "codeburn";
    tag = "v${version}";
    hash = "sha256-kIPDleTdeiaTpInJH86h5yQ1g0QhTmbO47978c+65is=";
  };

  npmDepsHash = "sha256-TSoz72VUsvpEby7VQ9T/qp8fI3J8Ra/+QPGuCBvW5FA=";

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
