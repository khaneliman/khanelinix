_: _final: prev: {
  sketchybar = prev.sketchybar.overrideAttrs (oldAttrs: {
    version = "2.20.1";

    src = prev.fetchFromGitHub {
      owner = "FelixKratz";
      repo = "SketchyBar";
      rev = "v2.20.1";
      hash = "sha256-dyo4J3Qszq7SSXdAXmgm7xFhWE5Eqtr7yZpNGmtuphY=";
    };

    # Create secondary sketchybar executable for dynamic island
    installPhase = /* bash */ ''
      ${oldAttrs.installPhase}
       cp ./bin/sketchybar $out/bin/dynamic-island-sketchybar
    '';
  });
}
