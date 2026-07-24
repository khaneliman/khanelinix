{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  wrapGAppsHook4,
  fontconfig,
  gtk4,
  libadwaita,
  webkitgtk_6_0,
  ...
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "limux";
  version = "0.1.21";

  src = fetchurl {
    url = "https://github.com/am-will/limux/releases/download/v${finalAttrs.version}/limux-${finalAttrs.version}-linux-x86_64.tar.gz";
    hash = "sha256-vt+hsiQWP5IxDQ/htlEKMOt/seppFBkoyz2AwieFBlE=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    wrapGAppsHook4
  ];

  buildInputs = [
    fontconfig
    gtk4
    libadwaita
    webkitgtk_6_0
  ];

  installPhase = ''
    runHook preInstall

    install -Dm755 limux $out/bin/limux
    install -Dm755 libexec/limux/limux-host $out/libexec/limux/limux-host
    install -Dm644 lib/libghostty.so $out/lib/limux/libghostty.so
    cp -r share/. $out/share/

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    $out/bin/limux --help | grep -q "limux CLI"

    runHook postInstallCheck
  '';

  meta = {
    description = "GPU-accelerated terminal workspace manager powered by Ghostty";
    homepage = "https://github.com/am-will/limux";
    changelog = "https://github.com/am-will/limux/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    maintainers = [ lib.maintainers.khaneliman ];
    mainProgram = "limux";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
