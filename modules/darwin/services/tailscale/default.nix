{
  config,
  lib,
  khanelinix-lib,
  pkgs,
  ...
}:
let
  inherit (lib) types mkIf;
  inherit (khanelinix-lib) mkOpt;

  cfg = config.khanelinix.services.tailscale;
in
{
  options.khanelinix.services.tailscale = {
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
