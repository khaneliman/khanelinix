_: _final: prev: {
  sketchybar = prev.sketchybar.overrideAttrs (oldAttrs: rec {
    # TODO: remove after https://github.com/NixOS/nixpkgs/pull/457857
    version = "2.23.0";
    src = prev.fetchFromGitHub {
      owner = "FelixKratz";
      repo = "SketchyBar";
      rev = "v${version}";
      hash = "sha256-PvKvevsSyRb6OfPWc2+1Bcfj2ngmgeP1URBoBiVeEdk=";
    };
    # Create secondary sketchybar executable for dynamic island
    installPhase = /* bash */ ''
      ${oldAttrs.installPhase}
       cp ./bin/sketchybar $out/bin/dynamic-island-sketchybar
    '';
  });
}
