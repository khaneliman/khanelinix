{ lib
, stdenv
, stdenvNoCC
, fetchzip
, installShellFiles
, testers
, yabai
}:

let
  pname = "yabai";
  version = "6.0.11";

  test-version = testers.testVersion {
    package = yabai;
    version = "yabai-v${version}";
  };

  _meta = with lib; {
    description = "A tiling window manager for macOS based on binary space partitioning";
    longDescription = ''
      yabai is a window management utility that is designed to work as an extension to the built-in
      window manager of macOS. yabai allows you to control your windows, spaces and displays freely
      using an intuitive command line interface and optionally set user-defined keyboard shortcuts
      using skhd and other third-party software.
    '';
    homepage = "https://github.com/koekeishiya/yabai";
    changelog = "https://github.com/koekeishiya/yabai/blob/v${version}/CHANGELOG.md";
    license = licenses.mit;
    platforms = platforms.darwin;
    mainProgram = "yabai";
    maintainers = with maintainers; [
      cmacrae
      shardy
      ivar
      khaneliman
    ];
  };
in
  {
    # Unfortunately compiling yabai from source on aarch64-darwin is a bit complicated. We use the precompiled binary instead for now.
    # See the comments on https://github.com/NixOS/nixpkgs/pull/188322 for more information.
    aarch64-darwin = stdenvNoCC.mkDerivation {
      inherit pname version;

      src = fetchzip {
        url = "https://github.com/koekeishiya/yabai/releases/download/v${version}/yabai-v${version}.tar.gz";
        hash = "sha256-CfyuWvxkeZQVuwMbX90CZF0RiY6q+o0WtfE3H9Z8q1o=";
      };

      nativeBuildInputs = [
        installShellFiles
      ];

      dontConfigure = true;
      dontBuild = true;

      installPhase = ''
        runHook preInstall

        mkdir -p $out
        cp -r ./bin $out
        installManPage ./doc/yabai.1

        runHook postInstall
      '';

      passthru.tests.version = test-version;

      meta = _meta // {
        sourceProvenance = with lib.sourceTypes; [
          binaryNativeCode
        ];
      };
    };
  }.${stdenv.hostPlatform.system} or { }
