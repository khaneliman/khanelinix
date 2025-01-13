{
  writeShellApplication,
  pkgs,
  lib,

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
      a=$(which "$1") && exec ${lib.getExe pkgs.khanelinix.trace-symlink} "$a"
    '';
}
