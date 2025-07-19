{ mkShell, pkgs, ... }:
mkShell {
  packages = with pkgs; [
    jdk
    jdk8
    jdk11
    jdk17
    temurin-jre-bin-17
    maven
    gradle
  ];

  shellHook = ''

    echo 🔨 Java DevShell


  '';
}
