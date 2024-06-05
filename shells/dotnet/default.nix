{ mkShell, pkgs, ... }:
let
  azure-artifacts-credential-provider = pkgs.stdenv.mkDerivation rec {
    name = "azure-artifacts-credential-provider";
    version = "1.1.1";

    src = pkgs.fetchurl {
      # TODO: build from source?
      url = "https://github.com/microsoft/artifacts-credprovider/releases/download/v${version}/Microsoft.Net6.NuGet.CredentialProvider.tar.gz";
      sha256 = "sha256-EfC3WVGKwNWxmv1JuH0e/g4u3trXCO8dv1wDMkvqcA4=";
    };

    buildPhase = ''
      mkdir -p $out/bin
      cp -r netcore $out/bin
    '';
  };
in
mkShell {
  packages = with pkgs; [
    (
      with dotnetCorePackages;
      combinePackages [
        dotnet-aspnetcore_6
        dotnet-runtime_6
        dotnet-sdk_6
        dotnet-aspnetcore_7
        dotnet-runtime_7
        dotnet-sdk_7
        dotnet_8.aspnetcore
        dotnet_8.runtime
        dotnet_8.sdk
      ]
    )
    azure-cli
    bicep
    csharp-ls
    dotnetbuildhelpers
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
  ];

  shellHook = ''

    export NUGET_PLUGIN_PATHS=${azure-artifacts-credential-provider}/bin/netcore/CredentialProvider.Microsoft/CredentialProvider.Microsoft.dll

    echo 🔨 Dotnet DevShell


  '';
}
