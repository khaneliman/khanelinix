{ pkgs, ... }:
{
  python = {
    name = "python";

    languages.python = {
      enable = true;
      version = "3.12";
      venv.enable = true;
    };

    packages = with pkgs; [
      black
      ruff
    ];

    enterShell = ''
      echo "🔨 Python DevShell"
      echo "Python $(python --version)"
    '';
  };
}
