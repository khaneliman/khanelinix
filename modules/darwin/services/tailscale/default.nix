{
  config,
  lib,
  ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.khanelinix) mkOpt;

  cfg = config.khanelinix.services.tailscale;
in
{
  options.khanelinix.services.tailscale = {
    enable = mkOpt types.bool true "Whether to enable Tailscale.";
  };

  # Use the signed Tailscale.app (NetworkExtension) rather than the open-source
  # tailscaled daemon from nixpkgs. The app receives OS sleep/wake and
  # DNS-restore callbacks that the daemon cannot: the NetworkExtension
  # entitlement is only granted to signed app bundles, so the nix-store daemon
  # leaves stale MagicDNS resolvers installed on wake and breaks resolution.
  config = mkIf cfg.enable {
    homebrew.casks = [ "tailscale-app" ];
  };
}
