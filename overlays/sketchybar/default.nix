_: _final: prev: {
  sketchybar = prev.sketchybar.overrideAttrs (oldAttrs: {
    doInstallCheck = false;
    version = "2.22.1-2025-09-11";
    src = prev.fetchFromGitHub {
      owner = "FelixKratz";
      repo = "SketchyBar";
      rev = "1b751317d6ab4d48d4a58f209425d5560b8ed38b";
      hash = "sha256-6fVcQPRqMI7nWfj4bPMt/myK5uYNtjZQ3gvO48UP2AI=";
    };
    # Create secondary sketchybar executable for dynamic island
    installPhase = # bash
      ''
        ${oldAttrs.installPhase}
         cp ./bin/sketchybar $out/bin/dynamic-island-sketchybar
      '';
  });
}
