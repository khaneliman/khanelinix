{ options
, config
, pkgs
, lib
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;
  cfg = config.khanelinix.tools.go;
in
{
  options.khanelinix.tools.go = {
    enable = mkBoolOpt false "Whether or not to enable Go support.";
  };

  config = mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [ go gopls ];
      sessionVariables = {
        GOPATH = "$HOME/work/go";
      };
    };
  };
}
