_: _final: prev: {
  kitty = prev.kitty.overrideAttrs (_oldAttrs: rec {
    version = "0.38.1";
    src = prev.fetchFromGitHub {
      owner = "kovidgoyal";
      repo = "kitty";
      tag = "v${version}";
      hash = "sha256-0M4Bvhh3j9vPedE/d+8zaiZdET4mXcrSNUgLllhaPJw=";
    };
  });
}
