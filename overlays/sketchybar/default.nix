_: _final: prev: {
  sketchybar = prev.sketchybar.overrideAttrs (oldAttrs: {
    version = "2.20.0";

    src = prev.fetchFromGitHub {
      owner = "FelixKratz";
      repo = "SketchyBar";
      rev = "v2.20.0";
      hash = "sha256-Nyje2F2OXtojbAGNgGPGdX8SEH75SWWpBKLFULb96n4=";
    };

    # Create secondary sketchybar executable for dynamic island
    installPhase = /* bash */ ''
      ${oldAttrs.installPhase}
       cp ./bin/sketchybar $out/bin/dynamic-island-sketchybar
    '';
  });
}
