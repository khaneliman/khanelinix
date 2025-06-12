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
          dotnet-aspnetcore_9
          dotnet-runtime_9
          dotnet-sdk_9
        ]
      )
    ]
    ++ dotnetDevShell.nativeBuildInputs;

  shellHook = ''

    ${dotnetDevShell.shellHook}

    export DOTNET_ROOT="${pkgs.dotnet-sdk_9}";

    echo 🔨 Dotnet 9 DevShell


  '';
}
