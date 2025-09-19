{
  mkShell,
  pkgs,
  ...
}:
mkShell {
  packages = with pkgs; [
    claude-code
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
