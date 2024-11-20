{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (flake.inputs.self.lib.khanelinix) mkBoolOpt;

  cfg = config.khanelinix.security.keyring;
in
{
  options.khanelinix.security.keyring = {
    enable = mkBoolOpt false "Whether to enable gnome keyring.";
  };

  config = mkIf cfg.enable { services.gnome.gnome-keyring.enable = true; };
}
