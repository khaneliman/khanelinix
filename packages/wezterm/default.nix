{ lib
, pkgs
}:
let
  inherit (pkgs) stdenv;
in
pkgs.rustPlatform.buildRustPackage rec {
  pname = "wezterm";
  version = "84ae00c868e711cf97b2bfe885892428f1131a1d";

  src = pkgs.fetchFromGitHub {
    owner = "wez";
    repo = "wezterm";
    rev = version;
    fetchSubmodules = true;
    hash = "sha256-Sx5NtapMe+CtSlW9mfxUHhzF+n9tV2j/St6pku26Rj0=";
  };

  postPatch = /* bash */ ''
    echo ${version} > .tag

    # tests are failing with: Unable to exchange encryption keys
    rm -r wezterm-ssh/tests
  '';

  cargoLock = {
    lockFile = ./Cargo.lock;
    allowBuiltinFetchGit = true;
  };

  nativeBuildInputs = with pkgs; [
    installShellFiles
    ncurses # tic for terminfo
    pkg-config
    python3
  ] ++ lib.optional stdenv.isDarwin perl;

  buildInputs = with pkgs; with xorg; [
    fontconfig
    zlib
  ] ++ lib.optionals stdenv.isLinux [
    libX11
    libxcb
    libxkbcommon
    openssl
    wayland
    xcbutil
    xcbutilimage
    xcbutilkeysyms
    xcbutilwm # contains xcb-ewmh among others
  ] ++ lib.optionals stdenv.isDarwin [
    darwin.apple_sdk_11_0.frameworks.Cocoa
    darwin.apple_sdk_11_0.frameworks.CoreGraphics
    darwin.apple_sdk_11_0.frameworks.Foundation
    libiconv
    darwin.apple_sdk_11_0.frameworks.System
    darwin.apple_sdk_11_0.frameworks.UserNotifications
  ];

  buildFeatures = [ "distro-defaults" ];

  env.NIX_LDFLAGS = lib.optionalString stdenv.isDarwin "-framework System";

  postInstall = /* bash */ ''
    mkdir -p $out/nix-support
    echo "${passthru.terminfo}" >> $out/nix-support/propagated-user-env-packages

    install -Dm644 assets/icon/terminal.png $out/share/icons/hicolor/128x128/apps/org.wezfurlong.wezterm.png
    install -Dm644 assets/wezterm.desktop $out/share/applications/org.wezfurlong.wezterm.desktop
    install -Dm644 assets/wezterm.appdata.xml $out/share/metainfo/org.wezfurlong.wezterm.appdata.xml

    install -Dm644 assets/shell-integration/wezterm.sh -t $out/etc/profile.d
    installShellCompletion --cmd wezterm \
      --bash assets/shell-completion/bash \
      --fish assets/shell-completion/fish \
      --zsh assets/shell-completion/zsh

    install -Dm644 assets/wezterm-nautilus.py -t $out/share/nautilus-python/extensions
  '';

  preFixup = lib.optionalString stdenv.isLinux /* bash */ ''
    patchelf \
      --add-needed "${pkgs.libGL}/lib/libEGL.so.1" \
      --add-needed "${pkgs.vulkan-loader}/lib/libvulkan.so.1" \
      $out/bin/wezterm-gui
  '' + lib.optionalString stdenv.isDarwin /* bash */ ''
    mkdir -p "$out/Applications"
    OUT_APP="$out/Applications/WezTerm.app"
    cp -r assets/macos/WezTerm.app "$OUT_APP"
    rm $OUT_APP/*.dylib
    cp -r assets/shell-integration/* "$OUT_APP"
    ln -s $out/bin/{wezterm,wezterm-mux-server,wezterm-gui,strip-ansi-escapes} "$OUT_APP"
  '';

  passthru = {
    tests = {
      all-terminfo = pkgs.nixosTests.allTerminfo;
      terminal-emulators = pkgs.nixosTests.terminal-emulators.wezterm;
    };
    terminfo = pkgs.runCommand "wezterm-terminfo"
      {
        nativeBuildInputs = [ pkgs.ncurses ];
      } /* bash */ ''
      mkdir -p $out/share/terminfo $out/nix-support
      tic -x -o $out/share/terminfo ${src}/termwiz/data/wezterm.terminfo
    '';
  };

  meta = with lib; {
    description = "GPU-accelerated cross-platform terminal emulator and multiplexer written by @wez and implemented in Rust";
    homepage = "https://wezfurlong.org/wezterm";
    license = licenses.mit;
    mainProgram = "wezterm";
    maintainers = with maintainers; [ SuperSandro2000 mimame ];
  };
}
