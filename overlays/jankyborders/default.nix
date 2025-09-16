_: _final: prev: {
  jankyborders = prev.jankyborders.overrideAttrs (_oldAttrs: {
    version = "1.7.0-unstable-2025-09-16";
    src = prev.fetchFromGitHub {
      owner = "FelixKratz";
      repo = "jankyborders";
      rev = "13c2e69380b490d1ef24213c8c5037208e649207";
      hash = "sha256-LG3I2Zp7GU9khrDTBRMO0+qhreVL+4rwAQRI+AbXbW0=";
    };
  });
}
