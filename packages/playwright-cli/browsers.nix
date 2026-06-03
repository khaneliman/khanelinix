# NixOS-runnable Playwright browsers pinned to the revisions that
# @playwright/cli's bundled playwright-core expects. nixpkgs only patches the
# browsers for its own (stable) playwright version, and @playwright/cli pins
# bleeding-edge alpha playwright-core, so the revisions never line up. Rather
# than reuse `playwright-driver.browsers`, mirror its recipe
# (pkgs/development/web/playwright/{chromium,chromium-headless-shell}.nix) at the
# revisions this CLI needs. Raw CfT downloads cannot run on NixOS without this
# autoPatchelf + fontconfig treatment.
#
# Bump these three pins together with the @playwright/cli version, then refresh
# the two zip hashes (set to lib.fakeHash and rebuild to learn the real values).
# Find them in the CLI's playwright-core browsers.json (`revision`,
# `browserVersion`) for chromium / chromium-headless-shell.
{
  lib,
  stdenv,
  fetchzip,
  linkFarm,
  makeWrapper,
  autoPatchelfHook,
  patchelf,
  makeFontsConf,

  alsa-lib,
  at-spi2-atk,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  glib,
  gobject-introspection,
  libGL,
  libgbm,
  libgcc,
  libxkbcommon,
  nspr,
  nss,
  pango,
  pciutils,
  systemd,
  vulkan-loader,
  libxrandr,
  libxfixes,
  libxext,
  libxdamage,
  libxcomposite,
  libx11,
  libxcb,
}:

let
  # Pins for @playwright/cli 0.1.13 -> playwright-core 1.61.0-alpha.
  chromiumRevision = "1224";
  headlessShellRevision = "1224";
  browserVersion = "149.0.7827.3";

  chromiumHash = "sha256-kcWvDL9FH1giwGWWkb7015kBbZBfshMlTBOb6DLfoQo=";
  headlessShellHash = "sha256-NBRxb/FM5vpRmVCmwn2iRbgJKrI1Xy0X5PYsFCqnVQ4=";

  fontconfig_file = makeFontsConf { fontDirectories = [ ]; };

  cftUrl = path: "https://cdn.playwright.dev/builds/cft/${browserVersion}/${path}";

  buildInputs = [
    alsa-lib
    at-spi2-atk
    atk
    cairo
    cups
    dbus
    expat
    glib
    gobject-introspection
    libgbm
    libgcc
    libxkbcommon
    nspr
    nss
    pango
    stdenv.cc.cc.lib
    systemd
    libx11
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libxcb
  ];

  chromium = stdenv.mkDerivation {
    name = "playwright-cli-chromium-${chromiumRevision}";

    src = fetchzip {
      url = cftUrl "linux64/chrome-linux64.zip";
      stripRoot = true;
      hash = chromiumHash;
    };

    nativeBuildInputs = [
      autoPatchelfHook
      patchelf
      makeWrapper
    ];
    inherit buildInputs;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/chrome-linux64
      cp -R . $out/chrome-linux64

      wrapProgram $out/chrome-linux64/chrome \
        --set-default SSL_CERT_FILE /etc/ssl/certs/ca-bundle.crt \
        --set-default FONTCONFIG_FILE ${fontconfig_file}

      runHook postInstall
    '';

    appendRunpaths = lib.makeLibraryPath [
      libGL
      vulkan-loader
      pciutils
    ];

    postFixup = ''
      # Replace bundled vulkan-loader; ours is already added to RPATH.
      rm "$out/chrome-linux64/libvulkan.so.1"
      ln -s -t "$out/chrome-linux64" "${lib.getLib vulkan-loader}/lib/libvulkan.so.1"
    '';
  };

  chromium-headless-shell = stdenv.mkDerivation {
    name = "playwright-cli-chromium-headless-shell-${headlessShellRevision}";

    src = fetchzip {
      url = cftUrl "linux64/chrome-headless-shell-linux64.zip";
      stripRoot = false;
      hash = headlessShellHash;
    };

    nativeBuildInputs = [
      autoPatchelfHook
      patchelf
    ];
    inherit buildInputs;

    buildPhase = ''
      runHook preBuild
      cp -R . $out
      runHook postBuild
    '';
  };
in
linkFarm "playwright-cli-browsers" [
  {
    name = "chromium-${chromiumRevision}";
    path = chromium;
  }
  {
    name = "chromium_headless_shell-${headlessShellRevision}";
    path = chromium-headless-shell;
  }
]
