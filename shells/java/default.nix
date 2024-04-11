{ mkShell, pkgs, ... }:
mkShell {
  buildInputs = with pkgs; [
    jdk
    maven
  ];

  shellHook = ''

    echo 🔨 Java DevShell


  '';
}
