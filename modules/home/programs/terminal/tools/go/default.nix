{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (flake.inputs.self.lib.khanelinix) mkBoolOpt;

  cfg = config.khanelinix.programs.terminal.tools.go;
in
{
  options.khanelinix.programs.terminal.tools.go = {
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
