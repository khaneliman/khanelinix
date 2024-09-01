{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.programs.graphical.addons.uwsm;
in
{
  options.${namespace}.programs.graphical.addons.uwsm = {
    enable = mkBoolOpt false "Whether or not to enable uwsm";
  };

  config = mkIf cfg.enable {
    programs.uwsm.enable = true;
  };
}
