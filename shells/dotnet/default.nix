{ mkShell, pkgs, ... }:
let
  artifacts-credprovider = pkgs.stdenv.mkDerivation rec {
    name = "artifacts-credprovider";
    version = "1.2.1";

    src = pkgs.fetchurl {
      # TODO: build from source?
      url = "https://github.com/microsoft/artifacts-credprovider/releases/download/v${version}/Microsoft.Net6.NuGet.CredentialProvider.tar.gz";
      sha256 = "sha256-wO5DHmEMjNTpDwx3rrZc9SkX3DxgW2LHs9W8un3jjo4=";
    };

    buildPhase = ''
      mkdir -p $out/bin
      cp -r netcore $out/bin
    '';
  };

  # TODO: upstream
  avrogen = pkgs.buildDotnetGlobalTool {
    pname = "avrogen";
    nugetName = "Apache.Avro.Tools";
    version = "1.12.0";
    nugetSha256 = "sha256-bR2ObY5hFCAWD326Y6NkN5FRyNWCKu4JaXlZ1dKY+XY=";
  };

  # TODO: upstream
  upgrade-assistant = pkgs.buildDotnetGlobalTool {
    pname = "upgrade-assistant";
    nugetName = "upgrade-assistant";
    version = "0.5.764";
    nugetSha256 = "sha256-z9R52jpRPDbr0WpAG7OV1Vufoy9+2hCu9RkrlnKZEDY=";
  };
in
mkShell {
  packages = with pkgs; [
    avrogen
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

    export NUGET_PLUGIN_PATHS=${artifacts-credprovider}/bin/netcore/CredentialProvider.Microsoft/CredentialProvider.Microsoft.dll

    echo 🔨 Dotnet DevShell


  '';
}
