{ mkShell, pkgs, ... }:
mkShell {
  packages = with pkgs; [
    jdk
    maven
  ];

  shellHook = ''

    echo 🔨 Java DevShell


  '';
}
