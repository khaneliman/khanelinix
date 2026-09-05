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
  version = "1.1.1";
  sources = {
    x86_64-linux = {
      platform = "linux";
      archivePlatform = "linux-x86_64";
      hash = "sha256-OPYtAbMt6wkHs9OacewwH9Njafb/0c8mLUrzhRd/ed8=";
    };
    aarch64-linux = {
      platform = "linux";
      archivePlatform = "linux-arm64";
      hash = "sha256-7WnmSzCPyxI6tUvzJ3v5yw1lEGT4hepaqw/1IMcXU5g=";
    };
    aarch64-darwin = {
      platform = "macos";
      archivePlatform = "darwin-arm64";
      hash = "sha256-/fqRVlLNt7qAhcyP/+0HLL4AklGqLJUaq92geowooYk=";
    };
  };
  source = sources.${stdenv.hostPlatform.system};
in
stdenv.mkDerivation {
  pname = "antigravity-acp";
  inherit version;

  src = fetchurl {
    url = "https://dl.google.com/agy-extensions/releases/${source.platform}/agy-acp-server-agy_acp_server_${version}-${source.archivePlatform}.zip";
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
