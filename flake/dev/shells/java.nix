{
  lib,
  mkShell,
  pkgs,
  ...
}:
let
  javaPackages = with pkgs; [
    jdk
    jdk8
    jdk11
    jdk17
    temurin-jre-bin-17
    maven
    gradle
  ];
in
mkShell {
  packages = javaPackages;

  shellHook = ''
    echo "🔨 Java DevShell"
    echo ""
    echo "📦 Available tools:"
    ${lib.concatMapStringsSep "\n" (
      pkg: ''echo "  - ${pkg.pname or pkg.name or "unknown"} (${pkg.version or "unknown"})"''
    ) javaPackages}
    echo ""
    echo "☕ Multiple JDK versions available (8, 11, 17, latest)"
    echo "🏗️  Build tools: Maven, Gradle"
  '';
}
