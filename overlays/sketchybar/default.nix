{ ... }: _final: prev: {
  sketchybar = prev.sketchybar.overrideAttrs (oldAttrs: {
    version = "2.16.1";

    src = prev.fetchFromGitHub {
      owner = "FelixKratz";
      repo = "SketchyBar";
      rev = "v2.16.1";
      hash = "sha256-H+bR5ZhUTrN2KAEdY/hnq6c3TEb1NQvPQ9uPo09gSM8=";
    };

    buildInputs = [
      prev.darwin.apple_sdk_11_0.frameworks.AppKit
      prev.darwin.apple_sdk_11_0.frameworks.CoreAudio
      prev.darwin.apple_sdk_11_0.frameworks.CoreWLAN
      prev.darwin.apple_sdk_11_0.frameworks.CoreVideo
      prev.darwin.apple_sdk_11_0.frameworks.DisplayServices
      prev.darwin.apple_sdk_11_0.frameworks.IOKit
      prev.darwin.apple_sdk_11_0.frameworks.MediaRemote
      prev.darwin.apple_sdk_11_0.frameworks.SkyLight
    ];

    # Create secondary sketchybar executable for dynamic island
    installPhase = ''
      ${oldAttrs.installPhase}
       cp ./bin/sketchybar $out/bin/dynamic-island-sketchybar
    '';
  });
}
