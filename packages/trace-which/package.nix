{
  writeShellApplication,
  inputs,
  lib,
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
      a=$(which "$1") && exec ${lib.getExe inputs.self.packages.${system}.trace-symlink} "$a"
    '';
}
