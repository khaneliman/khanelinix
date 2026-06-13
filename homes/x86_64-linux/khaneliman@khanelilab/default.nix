{
  config,
  lib,

  ...
}:
let
  inherit (lib.khanelinix) enabled;
in
{
  khanelinix = {
    user = {
      enable = true;
      name = "khaneliman";
    };

    programs = {
      terminal = {
        tools = {
          git = enabled;
          ssh = enabled;
        };
      };
    };

    services = {
      rclone = {
        enable = true;
        mounts = {
          dropbox.mountPoint = "/mnt/disks/dropbox";
          googledrive.mountPoint = "/mnt/disks/googledrive";
          googlephotos.mountPoint = "/mnt/disks/googlephotos";
          onedrive.mountPoint = "/mnt/disks/onedrive";
        };
      };

      sops = {
        enable = true;
        defaultSopsFile = lib.getFile "secrets/khanelilab/khaneliman/default.yaml";
        sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
      };
    };

    system = {
      xdg = enabled;
    };

    suites = {
      common = enabled;
      networking = enabled;
    };
  };

  sops.secrets = lib.mkIf config.khanelinix.services.sops.enable {
    nix = {
      sopsFile = lib.getFile "secrets/khaneliman/default.yaml";
      path = "${config.home.homeDirectory}/.config/nix/nix.conf";
    };
  };

  home.stateVersion = "26.05";
}
