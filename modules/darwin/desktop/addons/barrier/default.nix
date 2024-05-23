{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.desktop.addons.barrier;
in
{
  options.${namespace}.desktop.addons.barrier = {
    enable = mkBoolOpt false "Whether or not to enable barrier.";
  };

  config = mkIf cfg.enable {
    homebrew = {
      casks = [ "barrier" ];
    };
  };
}
