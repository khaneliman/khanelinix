{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Keep addresses stable for native clients of the former Docker DNS names.
  endpoints = {
    adminer = {
      address = "172.18.0.24";
      alias = "adminer";
    };
    ah-webapp = {
      address = "172.18.0.18";
      alias = "AH-WebApp";
    };
    ah-webapp-dev = {
      address = "172.18.0.19";
      alias = "AH-WebApp-Dev";
    };
    authelia = {
      address = "172.18.0.16";
      alias = "Authelia";
    };
    cleanuparr = {
      address = "172.18.0.2";
      alias = "Cleanuparr";
    };
    dockersocket = {
      address = "172.18.0.14";
      alias = "dockersocket";
    };
    flaresolverr = {
      address = "172.18.0.11";
      alias = "flaresolverr";
    };
    immich = {
      address = "172.18.0.12";
      alias = "immich";
    };
    kometa-ls = {
      address = "172.18.0.4";
      alias = "Kometa";
    };
    mariadb = {
      address = "172.18.0.22";
      alias = "mariadb";
    };
    mongodb = {
      address = "172.18.0.21";
      alias = "MongoDB";
    };
    neutarr = {
      address = "172.18.0.3";
      alias = "NeutArr";
    };
    nginx-proxy-manager = {
      address = "172.18.0.15";
      alias = "NginxProxyManager";
    };
    organizrv2 = {
      address = "172.18.0.17";
      alias = "organizrv2";
    };
    postgresql_immich = {
      address = "172.18.0.5";
      alias = "PostgreSQL_Immich";
    };
    profilarr = {
      address = "172.18.0.6";
      alias = "Profilarr";
    };
    qbittorrentvpn = {
      address = "172.18.0.23";
      alias = "qbittorrentvpn";
    };
    reclaimerr = {
      address = "172.18.0.7";
      alias = "Reclaimerr";
    };
    seerr = {
      address = "172.18.0.9";
      alias = "Seerr";
    };
    self-service-password = {
      address = "172.18.0.31";
      alias = "self-service-password";
    };
    wakapi = {
      address = "172.18.0.13";
      alias = "wakapi";
    };
  };
  nativeNames = [
    "plex"
    "binhex-jellyfin"
    "lidarr"
    "radarr"
    "sonarr"
    "prowlarr"
    "tautulli"
    "Redis"
    "redis"
  ];
  networkUnit = "khanelilab-container-networks.service";
in
{
  khanelinix.virtualisation.podman.enable = lib.mkForce false;
  virtualisation.docker.enable = true;
  virtualisation.oci-containers = {
    backend = "docker";
    containers = lib.mkMerge [
      (lib.mapAttrs (_: endpoint: {
        networks = [ "name=khaneproxy,ip=${endpoint.address},alias=${endpoint.alias}" ];
        extraOptions = map (name: "--add-host=${name}:172.18.0.1") nativeNames;
      }) endpoints)
      {
        dockersocket.networks = [
          "name=network_docker_socket_proxy,ip=172.21.0.2"
        ];
        timemachine = {
          networks = [ "name=br0,ip=192.168.4.2" ];
          extraOptions = lib.mkForce [ ];
        };
        immich.environment = {
          DB_HOSTNAME = lib.mkForce "PostgreSQL_Immich";
          DB_PORT = lib.mkForce "5432";
          REDIS_HOSTNAME = lib.mkForce "Redis";
        };
      }
    ];
  };

  networking.hosts =
    lib.mapAttrs' (
      name: endpoint:
      lib.nameValuePair endpoint.address (
        lib.unique [
          name
          endpoint.alias
        ]
      )
    ) endpoints
    // {
      "127.0.0.1" = nativeNames;
    };
  networking.firewall.interfaces.khaneproxy.allowedTCPPorts = [ 6379 ];

  services.redis = {
    package = pkgs.valkey;
    servers.khanelilab = {
      bind = "127.0.0.1 172.18.0.1";
      openFirewall = lib.mkForce false;
      settings.protected-mode = false;
    };
  };

  systemd.services =
    lib.mapAttrs' (
      _: container:
      lib.nameValuePair container.serviceName {
        requires = [ networkUnit ];
        after = [ networkUnit ];
        unitConfig.RequiresMountsFor = [
          "/mnt/user"
          "/mnt/pool"
        ];
      }
    ) config.virtualisation.oci-containers.containers
    // {
      redis-khanelilab = {
        requires = [ networkUnit ];
        after = [ networkUnit ];
      };
      khanelilab-container-networks = {
        description = "AustinServer container networks";
        requires = [ "docker.service" ];
        after = [
          "docker.service"
          "network-online.target"
        ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        path = [
          config.virtualisation.docker.package
          pkgs.jq
        ];
        script = ''
          ensure_network() {
            name="$1" driver="$2" subnet="$3" gateway="$4"
            shift 4
            if ! docker network inspect "$name" >/dev/null 2>&1; then
              docker network create --driver "$driver" --subnet "$subnet" --gateway "$gateway" "$@" "$name"
            fi
            docker network inspect "$name" | jq -e --arg driver "$driver" --arg subnet "$subnet" --arg gateway "$gateway" '
              .[0] | .Driver == $driver and
              any(.IPAM.Config[]; .Subnet == $subnet and .Gateway == $gateway)
            ' >/dev/null
          }
          ensure_network khaneproxy bridge 172.18.0.0/16 172.18.0.1 \
            -o com.docker.network.bridge.name=khaneproxy
          docker network inspect khaneproxy | jq -e '.[0].Options["com.docker.network.bridge.name"] == "khaneproxy"' >/dev/null
          ensure_network network_docker_socket_proxy bridge 172.21.0.0/16 172.21.0.1
          ensure_network br0 ipvlan 192.168.4.0/22 192.168.4.1 \
            -o parent=br0 -o ipvlan_mode=l2 --aux-address=server=192.168.4.42
          docker network inspect br0 | jq -e '.[0].Options.parent == "br0" and .[0].Options.ipvlan_mode == "l2"' >/dev/null
        '';
      };
    };
}
