_: _final: prev: {
  kitty = prev.kitty.overrideAttrs (
    prev.lib.optionalAttrs prev.stdenv.hostPlatform.isDarwin rec {
      version = "0.45.0-unstable-2026-01-20-pr9394";

      src = prev.fetchFromGitHub {
        owner = "kovidgoyal";
        repo = "kitty";
        rev = "fccb06e4bf9dd9cbc4024f386bf9ea9ac82a850e";
        hash = "sha256-mUfPaI9FFqd/+3jxzaEcAGiYnhYi9yUwS/mY68VASvE=";
      };

      inherit
        (
          (prev.buildGo124Module {
            pname = "kitty-go-modules";
            inherit src version;
            vendorHash = "sha256-Y5EnsTUJYuzGJaMsoBhSWGtCtnJeElkjrhyHnLVM0ZU=";
          })
        )
        goModules
        ;
    }
  );
}
