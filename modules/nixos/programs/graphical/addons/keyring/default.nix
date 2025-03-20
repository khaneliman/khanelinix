{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.programs.graphical.addons.keyring;
in
{
  options.${namespace}.programs.graphical.addons.keyring = {
    enable = lib.mkEnableOption "the passwords application";
  };

  config = mkIf cfg.enable { programs.seahorse.enable = true; };
}
