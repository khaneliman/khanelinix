{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.programs.graphical.addons.keyring;
in
{
  options.${namespace}.programs.graphical.addons.keyring = {
    enable = mkBoolOpt false "Whether to enable the passwords application.";
  };

  config = mkIf cfg.enable { programs.seahorse.enable = true; };
}
