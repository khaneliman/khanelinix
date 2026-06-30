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
  sources = {
    x86_64-linux = {
      url = "https://github.com/steipete/CodexBar/releases/download/v0.32.5/CodexBarCLI-v0.32.5-linux-x86_64.tar.gz";
      hash = "sha256-oFO+QfaqqWeBe8swpplw7VYphcCnj9t6CA+9422Wv2I=";
    };
    aarch64-linux = {
      url = "https://github.com/steipete/CodexBar/releases/download/v0.32.5/CodexBarCLI-v0.32.5-linux-aarch64.tar.gz";
      hash = "sha256-6wtwbr+pR9YZM00N2zId+UjA6qMn0c+ls9cw6vkS7Ak=";
    };
    aarch64-darwin = {
      url = "https://github.com/steipete/CodexBar/releases/download/v0.32.5/CodexBarCLI-v0.32.5-macos-arm64.tar.gz";
      hash = "sha256-4zN1x1tgwXc9w0ayFtiDLsudlDG50dtGbQRjwJg89kQ=";
    };
    x86_64-darwin = {
      url = "https://github.com/steipete/CodexBar/releases/download/v0.32.5/CodexBarCLI-v0.32.5-macos-x86_64.tar.gz";
      hash = "sha256-JEZ9GmRpPUvucXLXQDec6cIa4UFFoT0+1d7q5HRJbpw=";
    };
  };

  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "codexbar-cli is not packaged for ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "codexbar-cli";
  version = "0.32.5";

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
