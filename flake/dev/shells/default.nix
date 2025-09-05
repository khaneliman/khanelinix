{
  config,
  mkShell,
  pkgs,
  self',
  ...
}:
mkShell {
  packages = with pkgs; [
    act
    deadnix
    nh
    statix
    sops
    self'.formatter
  ];

  shellHook = ''
    ${config.pre-commit.installationScript}

    echo "🚀 Khanelinix development environment"
    echo "Available commands:"
    echo "  nix flake check       - Run all checks"
    echo "  nix fmt -- --no-cache - Format without cache"
    echo "  statix check          - Check for anti-patterns"
    echo "  deadnix               - Find unused code"
  '';
}
