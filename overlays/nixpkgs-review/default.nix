_: _final: prev: {
  nixpkgs-review = prev.nixpkgs-review.overridePythonAttrs {
    src = prev.fetchFromGitHub {
      owner = "Mic92";
      repo = "nixpkgs-review";
      rev = "b657186a6f2d8242106963742079b31d69c777f4";
      hash = "sha256-go08YwZbua0R3xSZrTEfe5h/OUJGgxrheX2rYN326/o=";
    };
    dependencies = with prev.python3Packages; [
      argcomplete
    ];
  };
}
