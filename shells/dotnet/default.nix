{ mkShell, pkgs, ... }:
let
  artifacts-credprovider = pkgs.stdenv.mkDerivation rec {
    name = "artifacts-credprovider";
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

  avrogen = pkgs.buildDotnetGlobalTool {
    # TODO: build from source?
    pname = "avrogen";
    nugetName = "Apache.Avro.Tools";
    version = "1.11.3";
    nugetSha256 = "sha256-nrG5NXCQwN1dOpf+fIXcbTjpYOHiQ++hBryYfpRFThU=";
  };
in
mkShell {
  packages = with pkgs; [
    avrogen
    azure-cli
    bicep
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
  ];

  shellHook = ''

    export NUGET_PLUGIN_PATHS=${artifacts-credprovider}/bin/netcore/CredentialProvider.Microsoft/CredentialProvider.Microsoft.dll

    echo 🔨 Dotnet DevShell


  '';
}
