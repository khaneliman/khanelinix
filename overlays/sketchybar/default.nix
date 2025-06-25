_: _final: prev: {
  sketchybar = prev.sketchybar.overrideAttrs (oldAttrs: {
    doInstallCheck = false;
    version = "2.22.1-2025-06-10";
    src = prev.fetchFromGitHub {
      owner = "FelixKratz";
      repo = "SketchyBar";
      rev = "1a192019c171e9cc7d87069dbd1822b5f25cdc89";
      hash = "sha256-2+CG02M923lMKHik3r8gPNJkCHp8pvSNpLDkInN8eDw=";
    };
    # Create secondary sketchybar executable for dynamic island
    installPhase = # bash
      ''
        ${oldAttrs.installPhase}
         cp ./bin/sketchybar $out/bin/dynamic-island-sketchybar
      '';
  });
}
