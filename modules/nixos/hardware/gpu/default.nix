{ khanelinix-lib, ... }:
let
  inherit (khanelinix-lib) mkBoolOpt;
in
{
  options.khanelinix.hardware.gpu = {
    enable = mkBoolOpt false "No-op for setting up hierarchy.";
  };
}
