{ pkgs, ... }:
{
  java = {
    name = "java";

    languages.java = {
      enable = true;
      jdk.package = pkgs.jdk17;
      maven.enable = true;
      gradle.enable = true;
    };

    packages = with pkgs; [
      jdk8
      jdk11
      temurin-jre-bin-17
    ];

    enterShell = ''
      echo "🔨 Java DevShell"
      echo "Java $(java -version 2>&1 | head -n1)"
    '';
  };
}
