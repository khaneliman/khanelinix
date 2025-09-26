{
  lib,
  devPkgs,
  ...
}:
let
  # Base dotnet packages and configuration
  baseDotnetShell = {
    packages = with devPkgs; [
      khanelinix.avrogen
      azure-cli
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
      export NUGET_PLUGIN_PATHS=${devPkgs.khanelinix.artifacts-credprovider}/bin/netcore/CredentialProvider.Microsoft/CredentialProvider.Microsoft.dll
    '';
  };

  # Create version-specific dotnet shell
  mkDotnetVersionShell =
    version:
    let
      # Version mapping for packages
      versionPackages = {
        "6" = with devPkgs; [
          dotnet-aspnetcore_6
          dotnet-runtime_6
          dotnet-sdk_6
        ];
        "7" = with devPkgs; [
          dotnet-aspnetcore_7
          dotnet-runtime_7
          dotnet-sdk_7
        ];
        "8" = with devPkgs; [
          dotnet-aspnetcore_8
          dotnet-runtime_8
          dotnet-sdk_8
        ];
        "9" = with devPkgs; [
          dotnet-aspnetcore_9
          dotnet-runtime_9
          dotnet-sdk_9
        ];
        "10" = with devPkgs; [
          dotnet-aspnetcore_10
          dotnet-runtime_10
          dotnet-sdk_10
        ];
      };

      versionSdks = {
        "6" = devPkgs.dotnet-sdk_6;
        "7" = devPkgs.dotnet-sdk_7;
        "8" = devPkgs.dotnet-sdk_8;
        "9" = devPkgs.dotnet-sdk_9;
        "10" = devPkgs.dotnet-sdk_10;
      };

      selectedPackages = versionPackages.${version} or (throw "Unsupported .NET version: ${version}");
      selectedSdk = versionSdks.${version} or (throw "Unsupported .NET version: ${version}");
    in
    devPkgs.mkShell {
      packages = [
        (devPkgs.dotnetCorePackages.combinePackages selectedPackages)
      ]
      ++ (
        if version == "6" then
          [
            # Special handling for .NET 6 csharp-ls override
            (devPkgs.csharp-ls.overrideAttrs (_oldAttrs: {
              useDotnetFromEnv = false;
              meta.badPlatforms = [ ];
            }))
          ]
        else
          [ ]
      )
      ++ baseDotnetShell.packages;

      shellHook = baseDotnetShell.shellHook + ''
        export DOTNET_ROOT="${selectedSdk}";
        echo 🔨 Dotnet ${version} DevShell
      '';
    };

  # Generate dotnet shells for each version
  dotnetVersions = [
    "6"
    "7"
    "8"
    "9"
    "10"
  ];
  versionedShells = lib.listToAttrs (
    lib.map (version: {
      name = "dotnet${version}";
      value = mkDotnetVersionShell version;
    }) dotnetVersions
  );

  # Base dotnet shell (defaults to .NET 8)
  baseShell = {
    dotnet = devPkgs.mkShell {
      inherit (baseDotnetShell) packages;
      shellHook = baseDotnetShell.shellHook + ''
        echo 🔨 Dotnet DevShell
      '';
    };
  };
in
baseShell // versionedShells
