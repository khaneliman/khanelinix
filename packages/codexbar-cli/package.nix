{
  lib,
  stdenv,
  fetchzip,
  autoPatchelfHook,
  makeWrapper,
  curl,
  openssl,
  sqlite,
  procps,
  lsof,
  which,
  tzdata,
  ...
}:

let
  version = "0.40.0";

  sources = {
    x86_64-linux = {
      url = "https://github.com/steipete/CodexBar/releases/download/v${version}/CodexBarCLI-v${version}-linux-x86_64.tar.gz";
      hash = "sha256-QI6eSz3LhkQHR6ootmrPfTincIrg8u/0vOpwgw8CjCk=";
    };
    aarch64-linux = {
      url = "https://github.com/steipete/CodexBar/releases/download/v${version}/CodexBarCLI-v${version}-linux-aarch64.tar.gz";
      hash = "sha256-gZi/3fYbgzv5I0EZWPulxXmMTFppsCiiavvdZmRTRjg=";
    };
    aarch64-darwin = {
      url = "https://github.com/steipete/CodexBar/releases/download/v${version}/CodexBarCLI-v${version}-macos-arm64.tar.gz";
      hash = "sha256-GEU1Nh+890//oocNHKw5Ew7GPi/SrKc/041SE7vUwl8=";
    };
    x86_64-darwin = {
      url = "https://github.com/steipete/CodexBar/releases/download/v${version}/CodexBarCLI-v${version}-macos-x86_64.tar.gz";
      hash = "sha256-a/mab/Dge//4Wgo51SHOdNMZ/JqTdJy2HfXuqHrhwyU=";
    };
  };

  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "codexbar-cli is not packaged for ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "codexbar-cli";
  inherit version;

  src = fetchzip (source // { stripRoot = false; });

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    curl
    openssl
    sqlite
    stdenv.cc.cc.lib
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/codexbar-cli $out/lib

    install -Dm0755 CodexBarCLI $out/bin/.codexbar-wrapped
    install -Dm0644 VERSION $out/share/codexbar-cli/VERSION

    ${lib.optionalString stdenv.hostPlatform.isLinux ''
      substitute ${./path-redirect.c.in} path-redirect.c \
        --replace-fail @ps@ ${lib.getExe' procps "ps"} \
        --replace-fail @lsof@ ${lib.getExe lsof} \
        --replace-fail @which@ ${lib.getExe which} \
        --replace-fail @tzdata@ ${tzdata}/share/zoneinfo

      $CC -shared -fPIC path-redirect.c -o $out/lib/codexbar-path-redirect.so -ldl -lssl -lcrypto

      makeWrapper $out/bin/.codexbar-wrapped $out/bin/codexbar \
        --set LD_PRELOAD $out/lib/codexbar-path-redirect.so
    ''}

    ${lib.optionalString (!stdenv.hostPlatform.isLinux) ''
      ln -s $out/bin/.codexbar-wrapped $out/bin/codexbar
    ''}

    runHook postInstall
  '';

  meta = {
    description = "CLI for CodexBar AI usage monitoring";
    homepage = "https://github.com/steipete/CodexBar";
    license = lib.licenses.mit;
    mainProgram = "codexbar";
    platforms = builtins.attrNames sources;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
