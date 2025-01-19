{ khanelinix-lib, ... }:
let
  inherit (khanelinix-lib) mkBoolOpt;
in
{
  imports = [
    ./amd
    ./intel
  ];

  options.khanelinix.hardware.cpu = {
    enable = mkBoolOpt false "No-op used for setting up hierarchy.";
  };
}
