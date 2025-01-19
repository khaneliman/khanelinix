{
  writeShellApplication,
  lib,
  self,
  system,
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
      a=$(which "$1") && exec ${lib.getExe self.packages.${system}.trace-symlink} "$a"
    '';
}
