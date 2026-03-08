{
  config,
  lib,
  ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.khanelinix) mkOpt mkBoolOpt;

  cfg = config.khanelinix.environments.home-network;

  username = config.khanelinix.user.name;
in
{
  options.khanelinix.environments.home-network = with types; {
    enable = lib.mkEnableOption "home network environment";
    serverHostname = mkOpt str "austinserver.local" "Home server hostname";
    enableNFSMounts = mkBoolOpt true "Enable NFS mounts to home server";
  };

  config = mkIf cfg.enable {
    # NFS automounts to home server
    fileSystems = mkIf cfg.enableNFSMounts (
      lib.mapAttrs'
        (mountPoint: serverPath: {
          name = mountPoint;
          value = {
            device = "${cfg.serverHostname}:${serverPath}";
            fsType = "nfs";
            options = [
              "noauto" # Don't mount at boot.
              "nofail" # Don't leave the system degraded if the server/export is unavailable.
              "_netdev" # Treat these as network mounts for ordering/shutdown.
              "x-systemd.automount" # Mount on first access.
              "x-systemd.mount-timeout=5s" # Fail quickly when the server/export is unavailable.
              "x-systemd.idle-timeout=1min" # Unmount after 1 minute of inactivity.
              "x-systemd.requires=network-online.target" # Wait for an active connection.
              "x-systemd.after=network-online.target" # Don't race network startup.
              "soft" # Prevent hangs if the server goes down.
              "timeo=20" # Keep access failures responsive.
              "retrans=1" # Don't spend long retrying missing exports.
            ];
          };
        })
        {
          "/mnt/austinserver/appdata" = "/mnt/user/appdata";
          "/mnt/austinserver/data" = "/mnt/user/data";
          "/mnt/austinserver/backup" = "/mnt/user/backup";
          "/mnt/austinserver/isos" = "/mnt/user/isos";
          "/mnt/dropbox" = "/mnt/disks/dropbox";
          "/mnt/disks/googledrive" = "/mnt/disks/googledrive";
          "/mnt/disks/onedrive" = "/mnt/disks/onedrive";
        }
    );

    # Enable NFS client
    services.rpcbind = mkIf cfg.enableNFSMounts {
      enable = true;
    };

    # Fix rpcbind environment variable warning
    systemd.services.rpcbind.environment = mkIf cfg.enableNFSMounts {
      RPCBIND_OPTIONS = "";
    };

    # System MPD music directory default
    services.mpd.settings.music_directory = lib.mkDefault "nfs://${cfg.serverHostname}/mnt/user/data/media/music";

    # SSH config for home server
    khanelinix.programs.terminal.tools.ssh = {
      extraConfig = lib.mkDefault ''
        Host server
          User ${username}
          Hostname ${cfg.serverHostname}
      '';
    };
  };
}
