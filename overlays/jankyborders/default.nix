_: _final: prev: {
  # TODO: remove after hits channel
  jankyborders = prev.jankyborders.overrideAttrs (_oldAttrs: rec {
    version = "1.8.3";
    src = prev.fetchFromGitHub {
      owner = "FelixKratz";
      repo = "jankyborders";
      tag = "v${version}";
      hash = "sha256-lc61PjaRZ8ZOWAFhsf/G3sQkd1oUyePHU43w4pt1AWY=";
    };
  });
}
