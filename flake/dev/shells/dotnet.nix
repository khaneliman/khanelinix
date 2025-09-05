{
  lib,
  pkgs,
  ...
}:
let
  # Base dotnet packages and configuration
  baseDotnetShell = {
    packages = with pkgs; [
      khanelinix.avrogen
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
    '';
  };

  # Create version-specific dotnet shell
  mkDotnetVersionShell =
    version:
    let
      # Version mapping for packages
      versionPackages = {
        "6" = with pkgs; [
          dotnet-aspnetcore_6
          dotnet-runtime_6
          dotnet-sdk_6
        ];
        "7" = with pkgs; [
          dotnet-aspnetcore_7
          dotnet-runtime_7
          dotnet-sdk_7
        ];
        "8" = with pkgs; [
          dotnet-aspnetcore_8
          dotnet-runtime_8
          dotnet-sdk_8
        ];
        "9" = with pkgs; [
          dotnet-aspnetcore_9
          dotnet-runtime_9
          dotnet-sdk_9
        ];
        "10" = with pkgs; [
          dotnet-aspnetcore_10
          dotnet-runtime_10
          dotnet-sdk_10
        ];
      };

      versionSdks = {
        "6" = pkgs.dotnet-sdk_6;
        "7" = pkgs.dotnet-sdk_7;
        "8" = pkgs.dotnet-sdk_8;
        "9" = pkgs.dotnet-sdk_9;
        "10" = pkgs.dotnet-sdk_10;
      };

      selectedPackages = versionPackages.${version} or (throw "Unsupported .NET version: ${version}");
      selectedSdk = versionSdks.${version} or (throw "Unsupported .NET version: ${version}");
    in
    pkgs.mkShell {
      packages = [
        (pkgs.dotnetCorePackages.combinePackages selectedPackages)
      ]
      ++ (
        if version == "6" then
          [
            # Special handling for .NET 6 csharp-ls override
            (pkgs.csharp-ls.overrideAttrs (_oldAttrs: {
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
    dotnet = pkgs.mkShell {
      inherit (baseDotnetShell) packages;
      shellHook = baseDotnetShell.shellHook + ''
        echo 🔨 Dotnet DevShell
      '';
    };
  };
in
baseShell // versionedShells
