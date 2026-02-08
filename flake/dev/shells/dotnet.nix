{
  lib,
  devPkgs,
  ...
}:
let
  baseDotnetShell = {
    packages = with devPkgs; [
      dotnetbuildhelpers
      dotnetPackages.Nuget
      mono
      msbuild
      netcoredbg
      roslyn
      upgrade-assistant
    ];

    shellHook = versionLabel: ''
      export NUGET_PLUGIN_PATHS=${devPkgs.khanelinix.artifacts-credprovider}/bin/netcore/CredentialProvider.Microsoft/CredentialProvider.Microsoft.dll
      export PATH="$PATH:$HOME/.dotnet/tools"

      echo "🔨 ${versionLabel}"
      echo ""
      echo "📦 Available tools:"
      echo "  - dotnet (SDK with all runtimes)"
      echo "  - dotnetbuildhelpers"
      echo "  - nuget"
      echo "  - mono"
      echo "  - msbuild"
      echo "  - netcoredbg"
      echo "  - roslyn"
      echo "  - upgrade-assistant"
      echo ""
      echo "🛠️  Global tools:"

      # Install global tools if not already installed
      if ! command -v dotnet-easydotnet &> /dev/null; then
        echo "  Installing EasyDotnet..."
        dotnet tool install --global EasyDotnet
      else
        echo "  ✓ dotnet-easydotnet"
      fi
      if ! command -v dotnet-ef &> /dev/null; then
        echo "  Installing dotnet-ef..."
        dotnet tool install --global dotnet-ef
      else
        echo "  ✓ dotnet-ef"
      fi
      echo ""
      echo "💡 Azure Artifacts credential provider configured"
    '';
  };

  # Create version-specific dotnet shell
  mkDotnetVersionShell =
    version:
    let
      versionSdks = {
        "8" = devPkgs.dotnet-sdk_8;
        "9" = devPkgs.dotnet-sdk_9;
        "10" = devPkgs.dotnet-sdk_10;
      };

      selectedSdk = versionSdks.${version} or (throw "Unsupported .NET version: ${version}");

      # Combine the SDK with all runtimes
      combinedDotnet = devPkgs.dotnetCorePackages.combinePackages (
        with devPkgs;
        [
          selectedSdk
          dotnet-runtime_8
          dotnet-runtime_9
          dotnet-runtime_10
          dotnet-aspnetcore_8
          dotnet-aspnetcore_9
          dotnet-aspnetcore_10
        ]
      );
    in
    devPkgs.mkShell {
      packages =
        baseDotnetShell.packages
        ++ [ combinedDotnet ]
        ++ (
          if version < "9" then
            [
              # Special handling for .NET csharp-ls override
              (devPkgs.csharp-ls.overrideAttrs (_oldAttrs: {
                useDotnetFromEnv = false;
                meta.badPlatforms = [ ];
              }))
            ]
          else
            [ ]
        );

      shellHook = ''
        export DOTNET_ROOT="${combinedDotnet}/share/dotnet";
        ${baseDotnetShell.shellHook "Dotnet ${version} DevShell"}
      '';
    };

  # Generate dotnet shells for each version
  dotnetVersions = [
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

  # Combine SDK 10 with all runtimes
  combinedDotnet10 = devPkgs.dotnetCorePackages.combinePackages (
    with devPkgs;
    [
      dotnet-sdk_10
      dotnet-runtime_8
      dotnet-runtime_9
      dotnet-runtime_10
      dotnet-aspnetcore_8
      dotnet-aspnetcore_9
      dotnet-aspnetcore_10
    ]
  );

  baseShell = {
    dotnet = devPkgs.mkShell {
      packages = baseDotnetShell.packages ++ [ combinedDotnet10 ];

      shellHook = ''
        export DOTNET_ROOT="${combinedDotnet10}/share/dotnet";
        ${baseDotnetShell.shellHook "Dotnet DevShell (latest - SDK 10)"}
      '';
    };
  };
in
baseShell // versionedShells
