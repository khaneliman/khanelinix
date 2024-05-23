{ mkShell, pkgs, ... }:
let
  azure-artifacts-credential-provider = pkgs.stdenv.mkDerivation rec {
    name = "azure-artifacts-credential-provider";
    version = "1.0.9";

    src = pkgs.fetchurl {
      # TODO: build from source?
      url = "https://github.com/microsoft/artifacts-credprovider/releases/download/v${version}/Microsoft.Net6.NuGet.CredentialProvider.tar.gz";
      sha256 = "sha256-7SNpqz/0c1RZ1G0we68ZGd2ucrsKFBp7fAD/7j7n9Bc=";
    };

    buildPhase = ''
      mkdir -p $out/bin
      cp -r netcore $out/bin
    '';
  };
in
mkShell {
  packages =
    with pkgs;
    [
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
      dotnetbuildhelpers
      netcoredbg
      powershell
      vimPlugins.neotest-dotnet
      vscode-extensions.ms-dotnettools.csharp
      omnisharp-roslyn
      roslyn
      roslyn-ls
      csharp-ls
      mono
      msbuild
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      azure-cli
      bicep
    ];

  shellHook = ''

    export NUGET_PLUGIN_PATHS=${azure-artifacts-credential-provider}/bin/netcore/CredentialProvider.Microsoft/CredentialProvider.Microsoft.dll

    echo 🔨 Dotnet DevShell


  '';
}
