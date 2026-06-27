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
    a=$(command -v "$1") && exec ${lib.getExe trace-symlink} "$a"
  '';
}
