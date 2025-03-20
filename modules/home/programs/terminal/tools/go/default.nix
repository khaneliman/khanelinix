{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.programs.terminal.tools.go;
in
{
  options.${namespace}.programs.terminal.tools.go = {
    enable = lib.mkEnableOption "Go support";
  };

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        go
        gopls
      ];

      sessionVariables = {
        GOPATH = "$HOME/work/go";
      };
    };
  };
}
