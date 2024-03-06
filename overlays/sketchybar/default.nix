_: _final: prev: {
  sketchybar = prev.sketchybar.overrideAttrs (oldAttrs: {
    version = "2.20.1-unstable";

    src = prev.fetchFromGitHub {
      owner = "FelixKratz";
      repo = "SketchyBar";
      rev = "0cc53dc1d05c98ede829178fff1f329005485011";
      hash = "sha256-AJKYW7XRZCgK4pafXs97/iu6yUz7lunmQWygTwah7/4=";
    };

    # Create secondary sketchybar executable for dynamic island
    installPhase = /* bash */ ''
      ${oldAttrs.installPhase}
       cp ./bin/sketchybar $out/bin/dynamic-island-sketchybar
    '';
  });
}
