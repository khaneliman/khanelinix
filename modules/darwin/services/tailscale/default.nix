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

    # Default off: every host sits on a LAN that a subnet router also
    # advertises, so accepting that route would shadow the interface's own link
    # route and hijack on-link traffic into the tunnel, breaking native LAN
    # connectivity and mDNS. Tailnet peers stay reachable by their 100.x
    # address regardless. Enable only on a roaming host that must reach
    # non-Tailscale devices on a remote subnet.
    acceptRoutes = lib.mkEnableOption "accepting subnet routes advertised by other Tailscale nodes";
  };

  # Use the signed Tailscale.app (NetworkExtension) rather than the open-source
  # tailscaled daemon from nixpkgs. The app receives OS sleep/wake and
  # DNS-restore callbacks that the daemon cannot: the NetworkExtension
  # entitlement is only granted to signed app bundles, so the nix-store daemon
  # leaves stale MagicDNS resolvers installed on wake and breaks resolution.
  config = mkIf cfg.enable {
    homebrew.casks = [ "tailscale-app" ];

    # The signed app keeps prefs in its own daemon state, not nix, so re-apply
    # accept-routes on every rebuild to keep the flake the source of truth.
    # Guarded and non-fatal: the app/daemon may not be running yet (e.g. first
    # activation before the cask installs, or pre-login boot).
    system.activationScripts.extraActivation.text = ''
      tsCli=""
      for c in /usr/local/bin/tailscale /opt/homebrew/bin/tailscale /Applications/Tailscale.app/Contents/MacOS/Tailscale; do
        if [ -x "$c" ]; then
          tsCli="$c"
          break
        fi
      done

      if [ -n "$tsCli" ] && "$tsCli" status >/dev/null 2>&1; then
        echo >&2 "Applying Tailscale accept-routes=${lib.boolToString cfg.acceptRoutes}..."
        "$tsCli" set --accept-routes=${lib.boolToString cfg.acceptRoutes} || true
      fi
    '';
  };
}
