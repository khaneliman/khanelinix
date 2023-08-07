{ options
, config
, lib
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.system.networking;
in
{
  options.khanelinix.system.networking = with types; {
    enable = mkBoolOpt false "Whether or not to enable networking support";
  };

  config = mkIf cfg.enable {
    networking = {
      dns = [ "1.1.1.1" "8.8.8.8" ];
    };
  };
}
