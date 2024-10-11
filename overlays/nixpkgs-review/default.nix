_: _final: prev: {
  # TODO: remove after in unstable
  nixpkgs-review = prev.nixpkgs-review.overrideAttrs (_oldAttrs: {
    version = "2.12.0";
    src = prev.fetchFromGitHub {
      owner = "Mic92";
      repo = "nixpkgs-review";
      rev = "refs/tags/2.12.0";
      hash = "sha256-yNdBqL3tceuoUHx8/j2y5ZTq1zeVDAm37RZtlCbC6rg=";
    };
  });
}
