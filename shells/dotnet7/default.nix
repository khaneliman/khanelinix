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
          dotnet-aspnetcore_7
          dotnet-runtime_7
          dotnet-sdk_7
        ]
      )
    ]
    ++ dotnetDevShell.nativeBuildInputs;

  shellHook = ''

    ${dotnetDevShell.shellHook}

    export DOTNET_ROOT="${pkgs.dotnet-sdk_7}";

    echo 🔨 Dotnet 7 DevShell


  '';
}
