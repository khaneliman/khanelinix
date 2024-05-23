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

  cfg = config.${namespace}.programs.terminal.tools.go;
in
{
  options.${namespace}.programs.terminal.tools.go = {
    enable = mkBoolOpt false "Whether or not to enable Go support.";
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
