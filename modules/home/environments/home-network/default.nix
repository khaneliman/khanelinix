{
  config,
  lib,
  osConfig ? { },
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib) types;
  inherit (lib.khanelinix) mkOpt;

  cfg = config.khanelinix.environments.home-network;

  # Get server hostnames from OS config if available, otherwise use local setting
  serverHostname = osConfig.khanelinix.environments.home-network.serverHostname or cfg.serverHostname;
  serverLocalHostname =
    osConfig.khanelinix.environments.home-network.serverLocalHostname or cfg.serverLocalHostname;

  # The Tailscale (MagicDNS) aliases are only emitted when the daemon/app is
  # enabled. Basic aliases resolve over mDNS (.local) to avoid Tailscale SSH
  # re-auth on local connections.
  tailscaleEnabled = osConfig.khanelinix.services.tailscale.enable or false;

  baseServer = {
    IdentityFile = "${config.home.homeDirectory}/.ssh/id_ed25519";
    IdentitiesOnly = true;
    User = config.khanelinix.user.name;
  };

  # Unraid root inventory access. Persist the key in
  # /boot/config/ssh/root.pubkeys, then copy it to /root/.ssh/authorized_keys
  # and restart sshd when active root key auth needs to be refreshed.
  rootServer = {
    BatchMode = true;
    IdentityFile = "${config.home.homeDirectory}/.ssh/id_ed25519";
    IdentitiesOnly = true;
    KbdInteractiveAuthentication = false;
    PasswordAuthentication = false;
    PreferredAuthentications = "publickey";
    User = "root";
  };
in
{
  options.khanelinix.environments.home-network = with types; {
    enable = lib.mkEnableOption "home network environment";
    serverHostname = mkOpt str "austinserver.taild8431e.ts.net" "Home server MagicDNS hostname";
    serverLocalHostname = mkOpt str "austinserver.local" "Home server LAN (mDNS) hostname";
  };

  config = mkIf cfg.enable {
    # MPD music directory for home network. Kept on the MagicDNS name so it
    # mounts both on-LAN and remotely; NFS is not subject to Tailscale SSH.
    khanelinix.services.mpd.musicDirectory = mkIf config.khanelinix.services.mpd.enable (
      lib.mkDefault "nfs://${serverHostname}/mnt/user/data/media/music"
    );

    # Run once from each client host that needs access:
    # ssh-copy-id -i ~/.ssh/id_ed25519.pub ${config.khanelinix.user.name}@${serverLocalHostname}
    programs.ssh.settings = lib.mkMerge [
      {
        "austinserver austinserver.local server" = lib.mkDefault (
          baseServer // { HostName = serverLocalHostname; }
        );
        "austinserver-root" = lib.mkDefault (rootServer // { HostName = serverLocalHostname; });
      }
      (mkIf tailscaleEnabled {
        "austinserver-ts" = lib.mkDefault (baseServer // { HostName = serverHostname; });
        "austinserver-root-ts" = lib.mkDefault (rootServer // { HostName = serverHostname; });
      })
    ];
  };
}
