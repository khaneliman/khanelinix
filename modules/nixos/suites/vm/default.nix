{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.khanelinix) enabled;

  cfg = config.khanelinix.suites.vm;
in
{
  options.khanelinix.suites.vm = {
    enable = lib.mkEnableOption "common vm configuration";
  };

  config = mkIf cfg.enable {
    khanelinix = {
      services = {
        spice-vdagentd = lib.mkDefault enabled;
        spice-webdav = lib.mkDefault enabled;
      };
    };
  };
}
