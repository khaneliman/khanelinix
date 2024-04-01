{ config
, lib
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.system.xkb;
in
{
  options.khanelinix.system.xkb = {
    enable = mkBoolOpt false "Whether or not to configure xkb.";
  };

  config = mkIf cfg.enable {
    console.useXkbConfig = true;

    services.xserver = {
      xkb = {
        layout = "us";
        options = "caps:escape";
      };
    };
  };
}
