{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.programs.terminal.tools.colorls;
in
{
  options.${namespace}.programs.terminal.tools.colorls = {
    enable = lib.mkEnableOption "colorls";
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
