{ config, lib, ... }:
let
  names = [
    "qbittorrentvpn"
    "postgresql_immich"
    "immich"
    "mariadb"
    "profilarr"
    "wakapi"
    "timemachine"
  ];
  secretFile = lib.getFile "secrets/khanelilab/services.yaml";
in
{
  sops.secrets = lib.listToAttrs (
    map (
      name:
      lib.nameValuePair "oci/${name}" {
        sopsFile = secretFile;
        key = name;
        restartUnits = [ "docker-${name}.service" ];
      }
    ) names
  );

  virtualisation.oci-containers.containers = lib.genAttrs names (name: {
    environmentFiles = [ config.sops.secrets."oci/${name}".path ];
  });
}
