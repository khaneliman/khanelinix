{ lib, ... }:
let
  inherit (lib.khanelinix) mkBoolOpt;
in
{
  options.khanelinix.hardware.cpu = {
    enable = mkBoolOpt false "No-op used for setting up hierarchy.";
  };
}
