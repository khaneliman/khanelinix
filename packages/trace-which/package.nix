{
  writeShellApplication,
  lib,
  trace-symlink,
  ...
}:
writeShellApplication {
  name = "trace-which";

  meta = {
    mainProgram = "trace-which";
  };

  checkPhase = "";

  text = ''
    a=$(which "$1") && exec ${lib.getExe trace-symlink} "$a"
  '';
}
