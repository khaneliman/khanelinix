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

  # Get server hostname from OS config if available, otherwise use local setting
  serverHostname = osConfig.khanelinix.environments.home-network.serverHostname or cfg.serverHostname;
in
{
  options.khanelinix.environments.home-network = with types; {
    enable = lib.mkEnableOption "home network environment";
    serverHostname = mkOpt str "austinserver.local" "Home server hostname";
  };

  config = mkIf cfg.enable {
    # MPD music directory for home network
    khanelinix.services.mpd.musicDirectory = mkIf config.khanelinix.services.mpd.enable (
      lib.mkDefault "nfs://${serverHostname}/mnt/user/data/media/music"
    );

    # Run once from each client host that needs access:
    # ssh-copy-id -i ~/.ssh/id_ed25519.pub ${config.khanelinix.user.name}@${serverHostname}
    programs.ssh.settings."austinserver austinserver.local server" = lib.mkDefault {
      HostName = serverHostname;
      IdentityFile = "${config.home.homeDirectory}/.ssh/id_ed25519";
      IdentitiesOnly = true;
      User = config.khanelinix.user.name;
    };

    # Unraid root inventory alias. Persist the key in
    # /boot/config/ssh/root.pubkeys, then copy it to /root/.ssh/authorized_keys
    # and restart sshd when active root key auth needs to be refreshed.
    programs.ssh.settings."austinserver-root" = lib.mkDefault {
      BatchMode = true;
      HostName = serverHostname;
      IdentityFile = "${config.home.homeDirectory}/.ssh/id_ed25519";
      IdentitiesOnly = true;
      KbdInteractiveAuthentication = false;
      PasswordAuthentication = false;
      PreferredAuthentications = "publickey";
      User = "root";
    };
  };
}
