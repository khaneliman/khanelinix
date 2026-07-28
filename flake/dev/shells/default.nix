{
  config,
  lib,
  mkShell,
  pkgs,
  self',
  ...
}:
let
  basePackages = with pkgs; [
    act
    deadnix
    namaka
    nh
    nix-unit
    statix
    sops
    self'.formatter

    # Lua
    lua
    emmylua-ls
    lua-language-server
  ];

  packages = lib.unique (
    basePackages ++ [ config.pre-commit.settings.package ] ++ config.pre-commit.settings.enabledPackages
  );
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
    ) basePackages}
    echo "  - pre-commit hooks and their tool dependencies"
    echo ""
    echo "🔧 Common commands:"
    echo "  nix flake check       - Run all checks"
    echo "  pre-commit run --all-files - Run repository hooks"
    echo "  nix fmt -- --no-cache - Format without cache"
    echo "  statix check          - Check for anti-patterns"
    echo "  deadnix               - Find unused code"
    echo "  namaka check          - Run snapshot tests"
    echo "  nh search <query>     - Search nixpkgs"
    echo "  sops                  - Manage secrets"
    echo "  nix-unit --flake .#tests - Run lib unit tests"
    echo "  lua-language-server   - Run LuaLS workspace checks"
    echo ""
    echo "💡 Tip: Run 'nix flake show' to see all available dev shells"
  '';
}
