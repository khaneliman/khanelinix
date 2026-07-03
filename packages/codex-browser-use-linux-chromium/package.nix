{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  makeWrapper,
  nodejs,
  ...
}:

stdenvNoCC.mkDerivation {
  pname = "codex-browser-use-linux-chromium";
  version = "0.1.0-unstable-2026-06-24";

  src = fetchFromGitHub {
    owner = "lampten";
    repo = "codex-browser-use-linux-chromium";
    rev = "a6e0564d14dbae5f7a7fa8b14aff1b01a9b2f038";
    hash = "sha256-k4amy/pIRy15ozzgbkv09nnJUyQJHKonhQEbGGWT3eA=";
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    install -d $out/share/codex-browser-use-linux-chromium
    cp -r bin src package.json $out/share/codex-browser-use-linux-chromium/
    install -Dm0644 LICENSE $out/share/licenses/codex-browser-use-linux-chromium/LICENSE

    makeWrapper ${lib.getExe nodejs} $out/bin/codex-browser-use-linux-chromium \
      --add-flags $out/share/codex-browser-use-linux-chromium/bin/codex-browser-use-linux-chromium.js

    # Runtime entry points, wrapped so Chromium (native-messaging manifest) and
    # codex (mcp_servers.node_repl) can run them straight from the store.
    makeWrapper ${lib.getExe nodejs} $out/bin/codex-native-host-bridge \
      --add-flags $out/share/codex-browser-use-linux-chromium/src/native-host/codex-native-host-bridge.js

    makeWrapper ${lib.getExe nodejs} $out/bin/codex-node-repl-mcp \
      --add-flags $out/share/codex-browser-use-linux-chromium/src/node-repl/codex-node-repl-mcp.js

    runHook postInstall
  '';

  doInstallCheck = true;

  installCheckPhase = ''
    runHook preInstallCheck

    # Upstream --help prints usage but exits non-zero
    ($out/bin/codex-browser-use-linux-chromium --help || true) | grep -q "Usage:"

    response="$(
      printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"khanelinix-smoke","version":"0"}}}' \
        | "$out/bin/codex-node-repl-mcp"
    )"
    grep -q '"protocolVersion":"2024-11-05"' <<< "$response"

    runHook postInstallCheck
  '';

  meta = {
    description = "Compatibility layer for Codex Browser Use with Linux Chromium";
    homepage = "https://github.com/lampten/codex-browser-use-linux-chromium";
    license = lib.licenses.mit;
    mainProgram = "codex-browser-use-linux-chromium";
    platforms = lib.platforms.linux;
  };
}
