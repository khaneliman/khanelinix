{ config
, lib
, options
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.system.networking;
in
{
  options.khanelinix.system.networking = {
    enable = mkBoolOpt false "Whether or not to enable networking support";
  };

  config = mkIf cfg.enable {
    networking = {
      dns = [ "1.1.1.1" "8.8.8.8" ];
    };
  };
}
