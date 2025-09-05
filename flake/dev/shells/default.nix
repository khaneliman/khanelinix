{
  config,
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
    commands = [
      {
        name = "check";
        help = "Run all flake checks";
        command = "nix flake check";
      }
      {
        name = "fmt";
        help = "Format code without cache";
        command = "nix fmt -- --no-cache";
      }
      {
        name = "lint";
        help = "Check for anti-patterns";
        command = "statix check";
      }
      {
        name = "find-dead";
        help = "Find unused code";
        command = "deadnix";
      }
    ];
    devshell.startup.pre-commit.text = config.pre-commit.installationScript;
  };
}
