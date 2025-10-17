_: _final: prev: {
  sketchybar = prev.sketchybar.overrideAttrs (oldAttrs: {
    doInstallCheck = false;
    version = "2.22.1-2025-10-11";
    src = prev.fetchFromGitHub {
      owner = "FelixKratz";
      repo = "SketchyBar";
      rev = "bd9030fe1478c2546ef5791d4bc6ffbcb0eac3be";
      hash = "sha256-4XjU59auyVjE+ER8ffmqhrKrW79kuLJ4aHfkxUNt+IY=";
    };
    # Create secondary sketchybar executable for dynamic island
    installPhase = # bash
      ''
        ${oldAttrs.installPhase}
         cp ./bin/sketchybar $out/bin/dynamic-island-sketchybar
      '';
  });
}
