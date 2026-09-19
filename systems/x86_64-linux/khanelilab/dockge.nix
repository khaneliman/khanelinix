{ config, ... }:
{
  virtualisation.oci-containers.containers.dockge = {
    image = "louislam/dockge:1";
    ports = [ "${config.khanelinix.system.networking.hostAddress}:5001:5001" ];
    networks = [ "name=khaneproxy,ip=172.18.0.29,alias=dockge" ];
    volumes = [
      "/mnt/user/appdata/dockge:/app/data"
      "/mnt/pool/appdata/compose-projects:/mnt/pool/appdata/compose-projects"
      "/var/run/docker.sock:/var/run/docker.sock"
    ];
    environment.DOCKGE_STACKS_DIR = "/mnt/pool/appdata/compose-projects";
  };
  # Docker resolves relative Compose bind sources in the host namespace.
  systemd.tmpfiles.rules = [
    "L /opt/stacks - - - - /mnt/pool/appdata/compose-projects"
  ];
  networking.hosts."172.18.0.29" = [ "dockge" ];
  systemd.services.docker-dockge.unitConfig.AssertPathIsDirectory =
    "/mnt/pool/appdata/compose-projects";
}
