{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.khanelinix.services.tailscale;
in
{
  options.khanelinix.services.tailscale = {
    enable = mkEnableOption "tailscale";
  };

  config = mkIf cfg.enable {
    services.tailscale-systray.enable = pkgs.stdenv.hostPlatform.isLinux;
  };
}
