_: _final: prev: {
  sketchybar = prev.sketchybar.overrideAttrs (oldAttrs: rec {
    version = "2.22.1";
    src = prev.fetchFromGitHub {
      owner = "FelixKratz";
      repo = "SketchyBar";
      rev = "v${version}";
      hash = "sha256-272lrH0ee4z4hcY4Hqt/UxjGwH6RFPEP4n0jz6Ab/+c=";
    };

    # Create secondary sketchybar executable for dynamic island
    installPhase = # bash
      ''
        ${oldAttrs.installPhase}
         cp ./bin/sketchybar $out/bin/dynamic-island-sketchybar
      '';
  });
}
