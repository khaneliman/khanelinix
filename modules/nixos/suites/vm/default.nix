{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (flake.inputs.self.lib.khanelinix) mkBoolOpt enabled;

  cfg = config.khanelinix.suites.vm;
in
{
  options.khanelinix.suites.vm = {
    enable = mkBoolOpt false "Whether or not to enable common vm configuration.";
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
