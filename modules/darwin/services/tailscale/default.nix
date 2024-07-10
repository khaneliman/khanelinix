{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.${namespace}) mkOpt;

  cfg = config.${namespace}.services.tailscale;
in
{
  options.${namespace}.services.tailscale = {
    enable = mkOpt types.bool true "Whether to enable the Nix daemon.";
  };

  config = mkIf cfg.enable {
    services = {
      tailscale = {
        enable = true;
        package = pkgs.tailscale;
      };
    };
  };
}
