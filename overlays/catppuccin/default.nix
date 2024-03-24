_: _final: prev: {
  # TODO: remove after nixos-unstable updated
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (
      _python-final: python-prev: {
        catppuccin = python-prev.catppuccin.overridePythonAttrs (_oldAttrs: rec {
          version = "1.3.2";

          src = prev.fetchFromGitHub {
            owner = "catppuccin";
            repo = "python";
            rev = "refs/tags/v${version}";
            hash = "sha256-spPZdQ+x3isyeBXZ/J2QE6zNhyHRfyRQGiHreuXzzik=";
          };

          # can be removed next version
          disabledTestPaths = [
            "tests/test_flavour.py" # would download a json to check correctness of flavours
          ];
        });
      }
    )
  ];
}
