_: _final: prev: {
  # TODO: remove stdenv and buildinputs override after next unstable
  sketchybar = (prev.sketchybar.override { inherit (prev) stdenv; }).overrideAttrs (oldAttrs: {
    buildInputs = [ prev.apple-sdk_15 ];

    # Create secondary sketchybar executable for dynamic island
    installPhase = # bash
      ''
        ${oldAttrs.installPhase}
         cp ./bin/sketchybar $out/bin/dynamic-island-sketchybar
      '';
  });
}
