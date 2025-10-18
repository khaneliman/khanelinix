{
  lib,
  mkShell,
  pkgs,
  ...
}:
let
  pythonPackages = with pkgs; [
    black
    (python3.withPackages (
      ps: with ps; [
        flake8
        ipython
        mypy
        pip
        pytest
      ]
    ))
    ruff
  ];
in
mkShell {
  packages = pythonPackages;

  shellHook = ''
    echo "🔨 Python DevShell"
    echo ""
    echo "📦 Available tools:"
    ${lib.concatMapStringsSep "\n" (
      pkg: ''echo "  - ${pkg.pname or pkg.name or "unknown"} (${pkg.version or "unknown"})"''
    ) pythonPackages}
    echo ""
    echo "🐍 Python packages: flake8, ipython, mypy, pip, pytest"
    echo ""
    echo "Setting up virtual environment..."
    python3 -m venv .venv
    source .venv/bin/activate
  '';
}
