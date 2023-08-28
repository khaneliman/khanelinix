{ options
, config
, lib
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.desktop.addons.barrier;
in
{
  options.khanelinix.desktop.addons.barrier = with types; {
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
