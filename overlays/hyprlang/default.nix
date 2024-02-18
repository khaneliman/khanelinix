_: _final: prev: {
  hyprlang = prev.hyprlang.overrideAttrs (_old: {
    version = "0.4.0";
    src = prev.fetchFromGitHub {
      owner = "hyprwm";
      repo = "hyprlang";
      rev = "v0.4.0";
      hash = "sha256-nW3Zrhh9RJcMTvOcXAaKADnJM/g6tDf3121lJtTHnYo=";
    };
  });
}
