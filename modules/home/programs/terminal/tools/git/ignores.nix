{
  ignores = [
    # General
    ".cache/"
    "tmp/"
    "*.tmp"
    "log/"
    ".DS_Store"
    "Desktop.ini"
    "Thumbs.db"
    "._*"
    ".Spotlight-V100"
    ".Trashes"

    # IDE
    "*.swp"
    ".idea/"
    ".~lock*"

    # C
    ".tags"
    "tags"
    "*~"
    "*.o"
    "*.so"
    "*.cmake"
    "CMakeCache.txt"
    "CMakeFiles/"
    "cmake-build-debug/"
    "compile_commands.json"
    ".ccls*"
    "*.out"

    # Nix
    "result"
    "result-*"
    ".direnv/"

    # Node
    "node_modules/"

    # Python
    "venv"
    ".venv"
    "*pyc"
    "*.egg-info/"
    "__pycached__/"
    ".mypy_cache"
  ];
}
