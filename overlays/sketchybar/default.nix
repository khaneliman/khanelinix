_: _final: prev: {
  sketchybar = prev.sketchybar.overrideAttrs (oldAttrs: {
    version = "2.20.1-unstable";

    src = prev.fetchFromGitHub {
      owner = "FelixKratz";
      repo = "SketchyBar";
      rev = "5e7b93221cad6c9704d7f34711ec013cddf58881";
      hash = "sha256-MlNnkff4sD/GkM1m+FH8ZtbNymgvxNOCoLWolwFEXTE=";
    };

    # Create secondary sketchybar executable for dynamic island
    installPhase = /* bash */ ''
      ${oldAttrs.installPhase}
       cp ./bin/sketchybar $out/bin/dynamic-island-sketchybar
    '';
  });
}
