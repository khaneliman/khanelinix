{ mkShell, pkgs, ... }:
mkShell {
  packages = with pkgs; [
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

  shellHook = ''

    echo 🔨 Python DevShell
    python3 -m venv .venv
    source .venv/bin/activate

  '';
}
