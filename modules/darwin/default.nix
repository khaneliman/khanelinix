{ inputs, ... }:
{
  imports = builtins.trace "DARWIN ----------------------------------------" [
    inputs.sops-nix.darwinModules.sops
  ];
}
