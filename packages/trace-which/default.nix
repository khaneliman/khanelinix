{
  writeShellApplication,
  pkgs,
  lib,
  namespace,
  ...
}:
writeShellApplication {
  name = "trace-which";

  meta = {
    mainProgram = "trace-which";
  };

  checkPhase = "";

  text = # bash
    ''
      a=$(which "$1") && exec ${lib.getExe pkgs.${namespace}.trace-symlink} "$a"
    '';
}
