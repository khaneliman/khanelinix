{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.terminal.tools.go;
in
{
  options.khanelinix.programs.terminal.tools.go = {
    enable = lib.mkEnableOption "Go support";
  };

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        go
        gopls
      ];

      sessionVariables = {
        GOPATH = "${config.home.homeDirectory}/work/go";
      };
    };
  };
}
