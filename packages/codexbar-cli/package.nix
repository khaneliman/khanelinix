{
  lib,
  stdenv,
  fetchzip,
  autoPatchelfHook,
  curl,
  sqlite,
  ...
}:

let
  sources = {
    x86_64-linux = {
      url = "https://github.com/steipete/CodexBar/releases/download/v0.29.1/CodexBarCLI-v0.29.1-linux-x86_64.tar.gz";
      hash = "sha256-k59GjkaXJZdYGUmqxqM+Qe1DdQ7wKVH7U4eYoNh5DuI=";
    };
    aarch64-linux = {
      url = "https://github.com/steipete/CodexBar/releases/download/v0.29.1/CodexBarCLI-v0.29.1-linux-aarch64.tar.gz";
      hash = "sha256-ZvNfUSelXDiuIIzyz7MURcWUytKdyI+tqyXVk7/CS0Y=";
    };
    aarch64-darwin = {
      url = "https://github.com/steipete/CodexBar/releases/download/v0.29.1/CodexBarCLI-v0.29.1-macos-arm64.tar.gz";
      hash = "sha256-tgeyOjDGw4jEEgP6kJPhckNYSGETXYJkeNmibMHMQf0=";
    };
    x86_64-darwin = {
      url = "https://github.com/steipete/CodexBar/releases/download/v0.29.1/CodexBarCLI-v0.29.1-macos-x86_64.tar.gz";
      hash = "sha256-K5neelkBGCI5WXQ3hSewvlr8odpBLD9N1EX6sxmDsXs=";
    };
  };

  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "codexbar-cli is not packaged for ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "codexbar-cli";
  version = "0.29.1";

  src = fetchzip (source // { stripRoot = false; });

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    curl
    sqlite
    stdenv.cc.cc.lib
  ];

  installPhase = ''
    runHook preInstall

    install -Dm0755 CodexBarCLI $out/bin/codexbar
    install -Dm0644 VERSION $out/share/codexbar-cli/VERSION

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
