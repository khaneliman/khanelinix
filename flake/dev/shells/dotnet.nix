{
  mkShell,
  pkgs,
  ...
}:
mkShell {
  packages = with pkgs; [
    pkgs.khanelinix.avrogen
    # FIXME: broken nixpkgs
    # azure-cli
    bicep
    csharpier
    dotnetbuildhelpers
    dotnetPackages.Nuget
    fsautocomplete
    mono
    msbuild
    netcoredbg
    powershell
    roslyn
    roslyn-ls
    rzls
    vimPlugins.neotest-dotnet
    vscode-extensions.ms-dotnettools.csharp
    upgrade-assistant
  ];

  shellHook = ''
    export NUGET_PLUGIN_PATHS=${pkgs.khanelinix.artifacts-credprovider}/bin/netcore/CredentialProvider.Microsoft/CredentialProvider.Microsoft.dll

    echo 🔨 Dotnet DevShell


  '';
}
