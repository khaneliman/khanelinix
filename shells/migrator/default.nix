{
  mkShell,
  pkgs,
  lib,
  ...
}:
mkShell {
  packages =
    with pkgs;
    [
      bun
      nodejs_20
      eslint_d
      typescript-language-server
      typescript
      claude-code
      csharpier
      (csharp-ls.overrideAttrs (_oldAttrs: {
        # NOTE: csharp-ls requires a very new dotnet 8 sdk. This causes issues with workspace dotnet
        # collisions because dotnet commands will run off the newest SDK breaking working with lower
        # version projects.
        useDotnetFromEnv = false;
        meta.badPlatforms = [ ];
      }))
      (
        with dotnetCorePackages;
        combinePackages [
          dotnet-aspnetcore_8
          dotnet-runtime_8
          dotnet-sdk_8
        ]
      )
    ]
    ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
      react-native-debugger
    ];

  shellHook = ''

    echo 🔨 Migrator DevShell


  '';
}
