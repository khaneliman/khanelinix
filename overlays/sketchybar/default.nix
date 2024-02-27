_: _final: prev: {
  sketchybar = prev.sketchybar.overrideAttrs (oldAttrs: {
    version = "2.20.1-unstable";

    src = prev.fetchFromGitHub {
      owner = "FelixKratz";
      repo = "SketchyBar";
      rev = "4c457077c92c8616dd2525388df47bf42560fdcf";
      hash = "sha256-xIwmlQtLBfH8ljHZWOF/Wvw15s6FOhhYgV96VK4qL4U=";
    };

    # Create secondary sketchybar executable for dynamic island
    installPhase = /* bash */ ''
      ${oldAttrs.installPhase}
       cp ./bin/sketchybar $out/bin/dynamic-island-sketchybar
    '';
  });
}
