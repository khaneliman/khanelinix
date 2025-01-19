{
  writeShellApplication,
  ...
}:
writeShellApplication {
  name = "build-by-path";

  meta = {
    mainProgram = "build-by-path";
    license = [ ./LICENSE ];
  };

  checkPhase = "";

  runtimeInputs = [ ];

  text = builtins.readFile ./build-by-path.sh;
}
