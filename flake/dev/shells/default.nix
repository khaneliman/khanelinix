{
  pkgs,
  self',
  ...
}:
{
  default = {
    name = "khanelinix";

    packages = with pkgs; [
      act
      deadnix
      nh
      statix
      sops
      self'.formatter
    ];

    scripts = {
      check = {
        description = "Run all flake checks";
        exec = "nix flake check";
      };
      fmt = {
        description = "Format code without cache";
        exec = "nix fmt -- --no-cache";
      };
      lint = {
        description = "Check for anti-patterns";
        exec = "statix check";
      };
      find-dead = {
        description = "Find unused code";
        exec = "deadnix";
      };
    };

    git-hooks.hooks = {
      treefmt = {
        enable = true;
        package = self'.formatter;
      };
    };

    enterShell = ''
      eval "$(direnv hook zsh)"

      echo "🚀 Khanelinix development environment"
      echo "Available commands: check, fmt, lint, find-dead"
    '';
  };
}
