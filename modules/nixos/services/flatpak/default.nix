{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.services.flatpak;
in
{
  options.${namespace}.services.flatpak = {
    enable = mkBoolOpt false "Whether or not to enable flatpak support.";
  };

  config = mkIf cfg.enable { services.flatpak.enable = true; };
}
