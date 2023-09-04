{ ... }: _final: prev: {
  sketchybar = prev.sketchybar.overrideAttrs (oldAttrs: {
    version = "2.16.3";

    src = prev.fetchFromGitHub {
      owner = "FelixKratz";
      repo = "SketchyBar";
      rev = "v2.16.3";
      hash = "sha256-PCAGIcO7lvIAEFXlJn/e9zG5kxvDABshxFbu/bXWX7o=";
    };

    # Create secondary sketchybar executable for dynamic island
    installPhase = ''
      ${oldAttrs.installPhase}
       cp ./bin/sketchybar $out/bin/dynamic-island-sketchybar
    '';
  });
}
