_: _final: prev: {
  nixpkgs-review = prev.nixpkgs-review.overridePythonAttrs {
    src = prev.fetchFromGitHub {
      owner = "GaetanLepage";
      repo = "nixpkgs-review";
      rev = "b39402126bdd48d7604634f428687267cf8f3b77";
      hash = "sha256-nDNxnyu3M7yuL/Md4BJZzFGc5kFzOIUhpwi45pafjw8=";
    };
    dependencies = with prev.python3Packages; [
      argcomplete
      requests
    ];
  };
}
