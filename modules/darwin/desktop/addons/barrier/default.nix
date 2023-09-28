{ config
, lib
, options
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.desktop.addons.barrier;
in
{
  options.khanelinix.desktop.addons.barrier = {
    enable = mkBoolOpt false "Whether or not to enable barrier.";
  };

  config = mkIf cfg.enable {
    homebrew = {
      casks = [
        "barrier"
      ];
    };
  };
}
