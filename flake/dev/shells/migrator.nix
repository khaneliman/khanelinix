{
  mkShell,
  pkgs,
  ...
}:
mkShell {
  packages = with pkgs; [
    # MCP
    bun
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

  shellHook = ''

    echo 🔨 Migrator DevShell


  '';
}
