{
  git,
  gh,
  lib,
  nix,
  nixpkgs-review,
  python3Packages,
  ...
}:

python3Packages.buildPythonApplication rec {
  pname = "vim-plugins-review";
  version = "0.1.0";

  format = "other";

  src = ./vim-plugins-review.py;
  dontUnpack = true;
  nativeBuildInputs = [ python3Packages.ruff ];
  doCheck = true;

  installPhase = ''
    mkdir -p $out/bin
    cp ${src} $out/bin/vim-plugins-review
    chmod +x $out/bin/vim-plugins-review
  '';

  checkPhase = ''
    PYTHONPYCACHEPREFIX="$TMPDIR/pycache" python -m py_compile ${src}
    ruff check ${src}
  '';

  propagatedBuildInputs = [
    gh
    git
    nix
    nixpkgs-review
  ];

  meta = {
    description = "Run nixpkgs-review for only actually changed vimPlugins attrs";
    license = lib.licenses.mit;
    mainProgram = "vim-plugins-review";
  };
}
