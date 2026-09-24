{
  lib,
  stdenv,
  fetchurl,
  unzip,
  autoPatchelfHook,
  makeWrapper,
  cacert,
  python3,
  ...
}:
let
  version = "1.2.1";
  sources = {
    x86_64-linux = {
      platform = "linux";
      archivePlatform = "linux-x86_64";
      hash = "sha256-n78L1YSiZHgWH2N8q9dRE/clQchC0Uj1eO8aap7cuEM=";
    };
    aarch64-linux = {
      platform = "linux";
      archivePlatform = "linux-arm64";
      hash = "sha256-fn70CIvBheGvQgQCng9OxCEK8gck8/8mIYasC86mqg4=";
    };
    aarch64-darwin = {
      platform = "macos";
      archivePlatform = "darwin-arm64";
      hash = "sha256-D6uZOIEuazKztUPmXk86ACXO73VUE9sTVC2am4HqgDw=";
    };
  };
  source = sources.${stdenv.hostPlatform.system};
in
stdenv.mkDerivation {
  pname = "antigravity-acp";
  inherit version;

  src = fetchurl {
    url = "https://dl.google.com/agy-extensions/releases/${source.platform}/agy-acp-server-${version}-${source.archivePlatform}.zip";
    inherit (source) hash;
  };

  nativeBuildInputs = [
    unzip
    makeWrapper
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];
  sourceRoot = ".";
  dontConfigure = true;
  dontBuild = true;
  # The executable contains an appended Python archive.
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 agy_acp_server.par "$out/bin/agy_acp_server.par"
    install -Dm755 localharness_external "$out/bin/localharness_external"
    runHook postInstall
  '';

  postFixup = ''
    wrapProgram "$out/bin/agy_acp_server.par" \
      --set-default SSL_CERT_FILE "${cacert}/etc/ssl/certs/ca-bundle.crt"
  '';

  # TCMalloc needs CPU sysfs, which the Linux build sandbox hides.
  # Run check-initialize.py against the built Linux output outside that sandbox.
  doInstallCheck = stdenv.hostPlatform.isDarwin;
  nativeInstallCheckInputs = [ python3 ];
  installCheckPhase = ''
    runHook preInstallCheck
    python ${./check-initialize.py} "$out/bin/agy_acp_server.par"
    runHook postInstallCheck
  '';

  meta = {
    description = "Google Antigravity ACP agent and native execution helper";
    homepage = "https://antigravity.google/docs/ide/extensions";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = lib.attrNames sources;
    mainProgram = "agy_acp_server.par";
  };
}
