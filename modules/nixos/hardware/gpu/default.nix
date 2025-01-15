{ lib, ... }:
let
  inherit (flake.inputs.self.lib.khanelinix) mkBoolOpt;
in
{
  options.khanelinix.hardware.gpu = {
    enable = mkBoolOpt false "No-op for setting up hierarchy.";
  };
}
