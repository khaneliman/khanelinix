{ mkShell, pkgs, ... }:
let
  dotnetDevShell = import ./dotnet.nix { inherit mkShell pkgs; };
in
mkShell {
  packages =
    with pkgs;
    [
      (
        with dotnetCorePackages;
        combinePackages [
          dotnet-aspnetcore_8
          dotnet-runtime_8
          dotnet-sdk_8
        ]
      )
    ]
    ++ dotnetDevShell.nativeBuildInputs;

  shellHook = ''

    ${dotnetDevShell.shellHook}

    export DOTNET_ROOT="${pkgs.dotnet-sdk_8}";

    echo 🔨 Dotnet 8 DevShell


  '';
}
