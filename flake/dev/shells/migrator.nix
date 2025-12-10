{
  lib,
  mkShell,
  pkgs,
  ...
}:
let
  migratorPackages = with pkgs; [
    # MCP
    bun
    nodejs
    # AI Scripts
    python3
    # Main tooling
    claude-code
    opencode
    # Dotnet repo
    (
      with dotnetCorePackages;
      combinePackages [
        dotnet-aspnetcore_8
        dotnet-runtime_8
        dotnet-sdk_8
      ]
    )
  ];
in
mkShell {
  packages = migratorPackages;

  shellHook = ''
    echo "🔨 Migrator DevShell"
    echo ""
    echo "📦 Available tools:"
    ${lib.concatMapStringsSep "\n" (
      pkg: ''echo "  - ${pkg.pname or pkg.name or "unknown"} (${pkg.version or "unknown"})"''
    ) migratorPackages}
    echo ""
    echo "🤖 AI-powered migration tooling"
    echo "🌐 MCP support via Bun"
    echo "⚙️  .NET 8 SDK included"
  '';
}
