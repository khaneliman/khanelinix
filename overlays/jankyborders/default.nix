_: _final: prev: {
  jankyborders = prev.jankyborders.overrideAttrs (_oldAttrs: rec {
    # TODO: remove when https://github.com/NixOS/nixpkgs/pull/357012 available
    version = "1.7.0";
    src = prev.fetchFromGitHub {
      owner = "FelixKratz";
      repo = "jankyborders";
      rev = "v${version}";
      hash = "sha256-PUyq3m244QyY7e8+/YeAMOxMcAz3gsyM1Mg/kgjGVgU=";
    };
  });
}
