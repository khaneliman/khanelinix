{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.programs.terminal.tools.colorls;
in
{
  options.${namespace}.programs.terminal.tools.colorls = {
    enable = mkBoolOpt false "Whether or not to enable colorls.";
  };

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [ colorls ];

      shellAliases = {
        lc = "colorls --sd";
        lcg = "lc --gs";
        lcl = "lc -1";
        lclg = "lc -1 --gs";
        lcu = "colorls -U";
        lclu = "colorls -U -1";
      };
    };
  };
}
