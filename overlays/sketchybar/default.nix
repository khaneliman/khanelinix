_: _final: prev: {
  sketchybar = prev.sketchybar.overrideAttrs (oldAttrs: {

    version = "2.19.3";

    src = prev.fetchFromGitHub {
      owner = "FelixKratz";
      repo = "SketchyBar";
      rev = "v2.19.3";
      hash = "sha256-QT926AnV9jLc1KvYks6ukIAcMbVHOupTJWQ6vBHpcxc=";
    };

    # Create secondary sketchybar executable for dynamic island
    installPhase = ''
      ${oldAttrs.installPhase}
       cp ./bin/sketchybar $out/bin/dynamic-island-sketchybar
    '';
  });
}
