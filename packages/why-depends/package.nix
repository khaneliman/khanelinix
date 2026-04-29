{
  lib,
  python3Packages,
  ...
}:

python3Packages.buildPythonApplication rec {
  pname = "why-depends";
  version = "0.1.0";

  format = "other"; # since it's not using setuptools/pyproject.toml

  src = ./why-depends.py;
  dontUnpack = true;
  nativeBuildInputs = [ python3Packages.ruff ];
  doCheck = true;

  installPhase = ''
    mkdir -p $out/bin
    cp ${src} $out/bin/why-depends
    chmod +x $out/bin/why-depends
  '';

  propagatedBuildInputs = [ ];

  checkPhase = ''
    python -m py_compile ${src}
    ruff check ${src}
    cp ${./why-depends_test.py} $PWD/why-depends_test.py
    cp ${src} $PWD/why-depends.py
    python why-depends_test.py
  '';

  meta = {
    mainProgram = "why-depends";
    description = "Trace why a package exists in a Nix system closure";
    license = lib.licenses.mit;
  };
}
