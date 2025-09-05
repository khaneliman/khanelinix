{ pkgs, ... }:
{
  python = {
    name = "python";
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
    devshell.startup.create-venv = {
      deps = [ ];
      text = ''python3 -m venv .venv && source .venv/bin/activate'';
    };
    devshell.motd = "🔨 Python DevShell";
  };
}
