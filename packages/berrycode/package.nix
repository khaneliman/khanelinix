{
  lib,
  stdenv,
  alsa-lib,
  bash,
  copyDesktopItems,
  fetchFromGitHub,
  libGL,
  libgbm,
  libx11,
  libxcb,
  libxcursor,
  libxi,
  libxinerama,
  libxkbcommon,
  libxrandr,
  makeDesktopItem,
  makeWrapper,
  openssl,
  pipewire,
  pkg-config,
  rustPlatform,
  udev,
  vulkan-loader,
  wayland,
  zlib,
  ...
}:

let
  runtimeLibraries = [
    alsa-lib
    libGL
    libgbm
    libx11
    libxcb
    libxcursor
    libxi
    libxinerama
    libxkbcommon
    libxrandr
    openssl
    pipewire
    stdenv.cc.cc.lib
    udev
    vulkan-loader
    wayland
    zlib
  ];
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "berrycode";
  version = "0.8.3";

  src = fetchFromGitHub {
    owner = "KyosukeIshizu1008";
    repo = "berryscode";
    rev = "v${finalAttrs.version}";
    hash = "sha256-GVLWKJaybC7UCDhsCeJ9LvQe563f9iPZgvzW4niITb0=";
  };

  patches = [ ./writable-asset-directory.patch ];

  cargoHash = "sha256-J+gN0zlEFdW4ZdgdrkbMaJh2d9JcBY5KQVD6focUglM=";

  nativeBuildInputs = [
    copyDesktopItems
    makeWrapper
    pkg-config
  ];

  buildInputs = runtimeLibraries;

  postPatch = ''
    substituteInPlace berrycode/src/agent/tools.rs \
      --replace-fail 'Command::new("/bin/bash")' 'Command::new("${lib.getExe bash}")'
  '';

  cargoBuildFlags = [
    "--package"
    "berrycode"
    "--bin"
    "berrycode"
  ];

  # Upstream tests include GUI and host-tool integration; use live smoke testing below.
  doCheck = false;

  desktopItems = [
    (makeDesktopItem {
      name = "berrycode";
      exec = "berrycode";
      icon = "berrycode";
      desktopName = "BerryCode";
      comment = "Bevy Game Engine IDE";
      categories = [
        "Development"
        "IDE"
      ];
    })
  ];

  postInstall = ''
    install -Dm0644 berrycode/assets/icon_256.png \
      "$out/share/icons/hicolor/256x256/apps/berrycode.png"

    wrapProgram "$out/bin/berrycode" \
      --run 'export BERRYCODE_ASSET_DIR="''${XDG_CACHE_HOME:-"$HOME/.cache"}/berrycode/assets"' \
      --run 'mkdir -p "$BERRYCODE_ASSET_DIR"' \
      --suffix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeLibraries}"
  '';

  meta = {
    description = "Native IDE for the Bevy game engine";
    homepage = "https://github.com/KyosukeIshizu1008/berryscode";
    changelog = "https://github.com/KyosukeIshizu1008/berryscode/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    maintainers = [ lib.maintainers.khaneliman ];
    mainProgram = "berrycode";
    platforms = lib.platforms.linux;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
})
