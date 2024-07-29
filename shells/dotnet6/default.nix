{ mkShell, pkgs, ... }:
let
  dotnetDevShell = import ../dotnet/default.nix { inherit mkShell pkgs; };
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
        ]
      )
      (csharp-ls.overrideAttrs (_oldAttrs: {
        # NOTE: csharp-ls requires a very new dotnet 8 sdk. This causes issues with workspace dotnet
        # collisions because dotnet commands will run off the newest SDK breaking working with lower
        # version projects.
        useDotnetFromEnv = false;
      }))
    ]
    ++ dotnetDevShell.nativeBuildInputs;

  shellHook =
    dotnetDevShell.shellHook
    + ''

      export DOTNET_ROOT="${pkgs.dotnet-sdk_6}";

      echo 🔨 Dotnet 6 DevShell


    '';
}
