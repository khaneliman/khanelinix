{ lib, ... }:
let
  inherit (lib.internal) mkBoolOpt;
in
{
  options.khanelinix.hardware.gpu = {
    enable = mkBoolOpt false "No-op for setting up hierarchy.";
  };
}
