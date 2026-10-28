{
  coreutils,
  writeShellApplication,
  ...
}:
writeShellApplication {
  name = "remove-imperative-nix-state";

  meta = {
    description = "Remove Nix channels and imperatively installed profiles";
    mainProgram = "remove-imperative-nix-state";
  };

  passthru.updateScript = null;

  runtimeInputs = [ coreutils ];

  text = builtins.readFile ./remove-imperative-nix-state.sh;
}
