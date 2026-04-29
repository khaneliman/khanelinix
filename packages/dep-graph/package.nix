{
  lib,
  graphviz,
  python3Packages,
  ...
}:

python3Packages.buildPythonApplication rec {
  pname = "nix-dep-graph";
  version = "0.1.0";

  format = "other";

  src = ./dep-graph.py;
  dontUnpack = true;
  nativeBuildInputs = [ python3Packages.ruff ];
  doCheck = true;

  installPhase = ''
    mkdir -p $out/bin
    cp ${src} $out/bin/nix-dep-graph
    chmod +x $out/bin/nix-dep-graph
  '';

  checkPhase = ''
    python -m py_compile ${src}
    ruff check ${src}
  '';

  propagatedBuildInputs = [ graphviz ];

  meta = {
    description = "Generate a dependency graph (dot/svg) for a Nix flake output";
    license = lib.licenses.mit;
    mainProgram = "nix-dep-graph";
  };
}
