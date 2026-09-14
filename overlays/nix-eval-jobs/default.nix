_: _final: prev: {
  nix-eval-jobs = prev.nix-eval-jobs.overrideAttrs (old: {
    buildInputs = (old.buildInputs or [ ]) ++ [ prev.mimalloc ];
    version = "2.35.3";
    src = prev.fetchFromGitHub {
      owner = "NixOS";
      repo = "nix-eval-jobs";
      rev = "v2.35.3";
      hash = "sha256-Ig1h/+qL5sj60fWiy44kQkXjapuff7vJXC9N0Ak8EkY=";
    };
  });
}
