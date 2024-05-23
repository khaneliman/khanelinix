{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.programs.terminal.tools.bandwhich;
in
{
  options.${namespace}.programs.terminal.tools.bandwhich = {
    enable = mkBoolOpt false "Whether or not to enable bandwhich.";
  };

  config = mkIf cfg.enable {
    programs.bandwhich = {
      enable = true;
    };
  };
}
