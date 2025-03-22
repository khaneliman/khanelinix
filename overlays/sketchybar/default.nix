_: _final: prev: {
  sketchybar = prev.sketchybar.overrideAttrs (oldAttrs: {
    doInstallCheck = false;
    version = "2.22.1-2025-03-22";
    src = prev.fetchFromGitHub {
      owner = "FelixKratz";
      repo = "SketchyBar";
      rev = "a8691a3fca676557bc6d8c69167e61df7462bbfe";
      hash = "sha256-oJ5fzyub5CYp3Is06uPflH63+3KS8R1FjVmQVG3VFIw=";
    };
    # Create secondary sketchybar executable for dynamic island
    installPhase = # bash
      ''
        ${oldAttrs.installPhase}
         cp ./bin/sketchybar $out/bin/dynamic-island-sketchybar
      '';
  });
}
