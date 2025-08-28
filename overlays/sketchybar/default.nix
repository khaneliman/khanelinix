_: _final: prev: {
  sketchybar = prev.sketchybar.overrideAttrs (oldAttrs: {
    doInstallCheck = false;
    version = "2.22.1-2025-08-14";
    src = prev.fetchFromGitHub {
      owner = "FelixKratz";
      repo = "SketchyBar";
      rev = "6a2f97504b1a7181d519bd300535e7152c2a3cdd";
      hash = "sha256-fx67l/mQcuxuE8UrWafiSF4n+uIgrioa32Qh3JDPYX8=";
    };
    # Create secondary sketchybar executable for dynamic island
    installPhase = # bash
      ''
        ${oldAttrs.installPhase}
         cp ./bin/sketchybar $out/bin/dynamic-island-sketchybar
      '';
  });
}
