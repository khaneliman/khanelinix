{ lib, ... }:
let
  inherit (lib.internal) mkBoolOpt;
in
{
  options.khanelinix.hardware.cpu = {
    enable = mkBoolOpt false "No-op used for setting up hierarchy.";
  };
}
