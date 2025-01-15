{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (flake.inputs.self.lib.khanelinix) mkBoolOpt;

  cfg = config.khanelinix.system.networking;
in
{
  options.khanelinix.system.networking = {
    enable = mkBoolOpt false "Whether or not to enable networking support";
  };

  config = mkIf cfg.enable {
    networking = {
      dns = [
        "1.1.1.1"
        "8.8.8.8"
      ];
    };

    system.defaults = {
      # firewall settings
      alf = {
        # 0 = disabled 1 = enabled 2 = blocks all connections except for essential services
        globalstate = 1;
        loggingenabled = 0;
        stealthenabled = 0;
      };
    };
  };
}
