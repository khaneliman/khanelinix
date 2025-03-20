{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.services.geoclue;
in
{
  options.${namespace}.services.geoclue = {
    enable = lib.mkEnableOption "geoclue support";
  };

  # TODO: app config https://github.com/NixOS/nixpkgs/blob/6e918e75e8bed152f24787aaad718649dc1963fe/nixos/modules/services/desktops/geoclue2.nix#L160-L173
  config = mkIf cfg.enable { services.geoclue2.enable = true; };
}
