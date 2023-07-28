{...}: _final: prev: {
  sketchybar = prev.sketchybar.overrideAttrs (oldAttrs: {
    # Create secondary sketchybar executable for dynamic island
    installPhase = ''
      ${oldAttrs.installPhase}
       cp ./bin/sketchybar $out/bin/dynamic-island-sketchybar
    '';
  });
}
