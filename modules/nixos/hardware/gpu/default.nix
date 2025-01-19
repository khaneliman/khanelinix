{ khanelinix-lib, ... }:
let
  inherit (khanelinix-lib) mkBoolOpt;
in
{
  imports = [
    ./amd
    ./nvidia
  ];

  options.khanelinix.hardware.gpu = {
    enable = mkBoolOpt false "No-op for setting up hierarchy.";
  };
}
