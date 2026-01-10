{
  config,
  lib,
  mkShell,
  pkgs,
  self',
  ...
}:
let
  packages = with pkgs; [
    act
    deadnix
    nh
    statix
    sops
    self'.formatter

    # Lua
    lua
    emmylua-ls
    luaPackages.luacheck
  ];
in
mkShell {
  inherit packages;

  shellHook = ''
    ${config.pre-commit.installationScript}

    echo "🚀 Khanelinix development environment"
    echo ""
    echo "📦 Available packages:"
    ${lib.concatMapStringsSep "\n" (
      pkg: ''echo "  - ${pkg.pname or pkg.name or "unknown"} (${pkg.version or "unknown"})"''
    ) packages}
    echo ""
    echo "🔧 Common commands:"
    echo "  nix flake check       - Run all checks"
    echo "  nix fmt -- --no-cache - Format without cache"
    echo "  statix check          - Check for anti-patterns"
    echo "  deadnix               - Find unused code"
    echo "  nh search <query>     - Search nixpkgs"
    echo "  sops                  - Manage secrets"
    echo "  luacheck .            - Lint Lua files"
    echo ""
    echo "💡 Tip: Run 'nix flake show' to see all available dev shells"
  '';
}
