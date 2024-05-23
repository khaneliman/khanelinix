{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt enabled;

  cfg = config.${namespace}.suites.vm;
in
{
  options.${namespace}.suites.vm = {
    enable = mkBoolOpt false "Whether or not to enable common vm configuration.";
  };

  config = mkIf cfg.enable {
    khanelinix = {
      services = {
        spice-vdagentd = enabled;
        spice-webdav = enabled;
      };
    };
  };
}
