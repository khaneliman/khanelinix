{ mkShell, pkgs, ... }:
let
  # TODO: upstream
  upgrade-assistant = pkgs.buildDotnetGlobalTool {
    pname = "upgrade-assistant";
    nugetName = "upgrade-assistant";
    version = "0.5.820";
    nugetSha256 = "sha256-GB+q5aZRkBTeXUbIPjkPsll6pSI/H6Iyh5mY53uT284=";
  };
in
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
    omnisharp-roslyn
    powershell
    roslyn
    roslyn-ls
    vimPlugins.neotest-dotnet
    vscode-extensions.ms-dotnettools.csharp
    upgrade-assistant
  ];

  shellHook = ''

    export NUGET_PLUGIN_PATHS=${pkgs.khanelinix.artifacts-credprovider}/bin/netcore/CredentialProvider.Microsoft/CredentialProvider.Microsoft.dll

    echo 🔨 Dotnet DevShell


  '';
}
