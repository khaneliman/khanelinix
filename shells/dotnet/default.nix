{ mkShell
, pkgs
, ...
}:
mkShell {
  buildInputs = with pkgs; [
    dotnet-sdk_8
    dotnet-runtime_8
    dotnet-aspnetcore_8
    dotnetbuildhelpers
    vscode-extensions.ms-dotnettools.csharp
    vimPlugins.neotest-dotnet
  ];

  shellHook = ''

    echo 🔨 Dotnet DevShell


  '';

}
