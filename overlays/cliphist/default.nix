_: _final: prev: {
  cliphist = prev.cliphist.overrideAttrs (_oldAttrs: rec {
    version = "0.6.1";

    src = prev.fetchFromGitHub {
      owner = "sentriz";
      repo = "cliphist";
      rev = "refs/tags/v${version}";
      hash = "sha256-tImRbWjYCdIY8wVMibc5g5/qYZGwgT9pl4pWvY7BDlI=";
    };

    vendorHash = "sha256-gG8v3JFncadfCEUa7iR6Sw8nifFNTciDaeBszOlGntU=";
  });
}
