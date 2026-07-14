{
  apple-sdk_15,
  boost,
  buildNpmPackage,
  cmake,
  curl,
  fetchFromGitHub,
  fetchzip,
  lib,
  libopus,
  llvmPackages,
  miniupnpc,
  nlohmann_json,
  openssl,
  pkg-config,
  stdenv,
  ...
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "lumen";
  version = "unstable-2026-02-18";

  src = fetchFromGitHub {
    owner = "trollzem";
    repo = "Lumen";
    rev = "5c3bd0f4109eb4069d10ee1a8201b9bf3a328018";
    hash = "sha256-+vzWBYrXMompedxNKtAaf+KIEdWR+bo1x/ZAtlYmUDw=";
    fetchSubmodules = true;
  };

  ui = buildNpmPackage {
    inherit (finalAttrs) src version;
    pname = "lumen-ui";
    npmDepsHash = "sha256-9Yvfxg71Mwck6koZcMLoq5mhsgs7Y4/4V1XwQ00eia4=";

    installPhase = ''
      runHook preInstall

      mkdir -p "$out"
      cp -a . "$out"/

      runHook postInstall
    '';
  };

  ffmpegPreparedBinaries = fetchzip {
    url = "https://github.com/LizardByte/build-deps/releases/download/v2026.516.30821/Darwin-arm64-ffmpeg.tar.gz";
    hash = "sha256-xkfwLJgb7uz1H7mJrQFW79w2T/T/Zv7biXlvXz5UvXc=";
  };

  postPatch = ''
    substituteInPlace cmake/targets/common.cmake \
      --replace-fail 'find_program(NPM npm REQUIRED)' ""

    substituteInPlace src/platform/macos/virtual_display.m \
      --replace-fail '#include <pthread.h>' $'#include <mach-o/dyld.h>\n#include <pthread.h>'

    echo 'set(FETCH_CONTENT_BOOST_USED TRUE)' >> cmake/dependencies/Boost_Sunshine.cmake
    echo 'include_directories(SYSTEM ''${FFMPEG_INCLUDE_DIRS})' >> cmake/dependencies/ffmpeg.cmake
  '';

  nativeBuildInputs = [
    cmake
    llvmPackages.lld
    pkg-config
  ];

  buildInputs = [
    apple-sdk_15
    boost
    curl
    libopus
    miniupnpc
    nlohmann_json
    openssl
  ];

  cmakeFlags = [
    "-Wno-dev"
    (lib.cmakeBool "BOOST_USE_STATIC" false)
    (lib.cmakeBool "BUILD_DOCS" false)
    (lib.cmakeFeature "CMAKE_CXX_STANDARD" "23")
    (lib.cmakeFeature "OPENSSL_ROOT_DIR" "${openssl.dev}")
    (lib.cmakeFeature "FFMPEG_PREPARED_BINARIES" "${finalAttrs.ffmpegPreparedBinaries}")
    (lib.cmakeFeature "SUNSHINE_ASSETS_DIR" "${placeholder "out"}/share/lumen/assets")
    (lib.cmakeBool "SUNSHINE_BUILD_HOMEBREW" true)
    (lib.cmakeBool "SUNSHINE_ENABLE_TRAY" true)
    (lib.cmakeFeature "SUNSHINE_PUBLISHER_NAME" "khanelinix")
    (lib.cmakeFeature "SUNSHINE_PUBLISHER_WEBSITE" "https://github.com/khaneliman/khanelinix")
    (lib.cmakeFeature "SUNSHINE_PUBLISHER_ISSUE_URL" "https://github.com/trollzem/Lumen/issues")
  ];

  env = {
    BUILD_VERSION = finalAttrs.version;
    BRANCH = "main";
    COMMIT = "5c3bd0f";
    NIX_CFLAGS_COMPILE = "-isystem ${finalAttrs.ffmpegPreparedBinaries}/include";
    NIX_CFLAGS_LINK = "-fuse-ld=lld";
  };

  buildFlags = [
    "sunshine"
    "vd_helper"
  ];

  postBuild = ''
    $CC -framework CoreGraphics -o get_display_origin ../src/platform/macos/get_display_origin.m
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 sunshine "$out/libexec/lumen/sunshine"
    install -Dm755 vd_helper "$out/libexec/lumen/vd_helper"
    install -Dm755 get_display_origin "$out/libexec/lumen/get_display_origin"
    install -Dm644 ../hid_entitlements.plist "$out/share/lumen/hid_entitlements.plist"

    mkdir -p "$out/share/lumen/assets"
    cp -R assets/. "$out/share/lumen/assets/"
    # The npm build's outDir is build/assets/web; copy the inner tree so
    # index.html lands at assets/web/index.html where sunshine expects it.
    cp -R ${finalAttrs.ui}/build/assets/web "$out/share/lumen/assets/web"
    install -Dm755 ../scripts/*.sh -t "$out/share/lumen/scripts"

    makeWrapper="$out/bin/lumen"
    mkdir -p "$out/bin"
    printf '%s\n' \
      '#!/bin/sh' \
      'exec "'"$out"'/libexec/lumen/sunshine" "$@"' \
      > "$makeWrapper"
    chmod +x "$makeWrapper"

    runHook postInstall
  '';

  meta = {
    description = "Native macOS game streaming host for Moonlight";
    homepage = "https://github.com/trollzem/Lumen";
    license = lib.licenses.gpl3Only;
    mainProgram = "lumen";
    platforms = lib.platforms.darwin;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
})
