_: _final: prev: {
  sketchybar = prev.sketchybar.overrideAttrs (oldAttrs: rec {
    # TODO: remove when https://github.com/NixOS/nixpkgs/pull/357010 available
    version = "2.22.0";
    src = prev.fetchFromGitHub {
      owner = "FelixKratz";
      repo = "sketchybar";
      rev = "v${version}";
      hash = "sha256-0082rRSfIKJFTAzmJ65ItEdLSwjFks5ZkTlVZqaWKEw=";
    };

    # Create secondary sketchybar executable for dynamic island
    installPhase = # bash
      ''
        ${oldAttrs.installPhase}
         cp ./bin/sketchybar $out/bin/dynamic-island-sketchybar
      '';
  });
}
