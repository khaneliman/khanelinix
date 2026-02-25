_: _final: prev: {
  kitty = prev.kitty.overrideAttrs rec {
    version = "0.45.0-unstable-2026-02-25";

    src = prev.fetchFromGitHub {
      owner = "kovidgoyal";
      repo = "kitty";
      rev = "a823f72e0ed21d5eb2d36b86affd79dec5396ad1";
      hash = "sha256-fz59mrGF45mfYSzbvtT+TSO7u6yCMhz0OHblJZI2e9E=";
    };

    inherit
      (
        (prev.buildGo124Module {
          pname = "kitty-go-modules";
          inherit src version;
          vendorHash = "sha256-Z+rLtcxUOit43n7FmMKTCRyTPtv5PGplu5OUEfcvucc=";
        })
      )
      goModules
      ;
  };
}
