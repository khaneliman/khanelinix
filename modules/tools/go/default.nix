{
  options,
  config,
  pkgs,
  lib,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.tools.go;
in {
  options.khanelinix.tools.go = with types; {
    enable = mkBoolOpt false "Whether or not to enable Go support.";
  };

  config = mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [go gopls];
      sessionVariables = {
        GOPATH = "$HOME/work/go";
      };
    };
  };
}
