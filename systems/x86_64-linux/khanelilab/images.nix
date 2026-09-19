{ lib, ... }:
{
  # A cutover must not silently upgrade stateful applications through moving tags.
  virtualisation.oci-containers.containers =
    lib.mapAttrs
      (_: image: {
        image = lib.mkForce image;
      })
      {
        adminer = "adminer@sha256:e82c16620650d359b87284b598d9ae03e5d95f3412f45d1ef3936b803445f1ae";
        ah-webapp = "ghcr.io/khaneliman/austin-horstman-webapp@sha256:4d5d749d062946fa8ea33259eec2b5b5eb331572076cdb87ce58deaa5b459505";
        ah-webapp-dev = "ghcr.io/khaneliman/austin-horstman-webapp@sha256:f881f49335b88e53757883540b30531e296329b8f90514d09b0b0b79c3d9e9ec";
        authelia = "authelia/authelia@sha256:bd97cff4fcbf715b5ff1f9ae286afbe6033afce385302520b0368122d43a6f54";
        cleanuparr = "ghcr.io/cleanuparr/cleanuparr@sha256:4ad626da7e1d2774ca51bbfa812f832d5639264b3fe308909e47de02ba2188f7";
        dockersocket = "ghcr.io/tecnativa/docker-socket-proxy@sha256:1f5038b54f06c3e18422902cf00ba21803d1c97805aae032e5e6673d532d3459";
        dockge = "louislam/dockge@sha256:335c6368b880ecc203236ed89e6e5232e0d6578e8ef5920e4a502390451502bf";
        flaresolverr = "flaresolverr/flaresolverr@sha256:c80ae007ce2ccdcd217a12426e4f039ef763ff90738c808d38810c3e59323767";
        hermes-docker-proxy = "ghcr.io/tecnativa/docker-socket-proxy@sha256:1f5038b54f06c3e18422902cf00ba21803d1c97805aae032e5e6673d532d3459";
        immich = "ghcr.io/imagegenius/immich@sha256:1318aa448e829aba60611599fe77650b88286d62e2d1de3606440b045c8f735e";
        kometa = "kometateam/kometa@sha256:6c3971a4aaa928b045e5f22514196b6db7f9b2b186158ebfe3239f4b328dfb0a";
        mariadb = "linuxserver/mariadb@sha256:75ffa39d652653e73848328a667d169a20a1e084fd51a66c4be3eb754a2492c9";
        mongodb = "mongo@sha256:5d7043a4ffe02b9ed1b6e0bab057546981af5ca0a79107e9c461e49bc44c0a7b";
        neutarr = "iampuid0/neutarr@sha256:c3df05a854c93aac640708e002e8fe85193f73da8406c8a230a5484a342a1107";
        nginx-proxy-manager = "jlesage/nginx-proxy-manager@sha256:7018287bde921c88a96de59571fec6370f0c818d8d5942e012794cddb7f0a3fa";
        organizrv2 = "organizr/organizr@sha256:1ce319d73cdfd2666ec7ef21e15907531fabc8a6f333c4ac61e2b2e9d2d162f5";
        postgresql_immich = "ghcr.io/immich-app/postgres@sha256:1a078b237c1d9b420b0ee59147386b4aa60d3a07a8e6a402fc84a57e41b043a4";
        profilarr = "santiagosayshey/profilarr@sha256:8a514f8429cd33885166facc9eb6504fa9ded056c737609e5e8ef32ae0afb350";
        qbittorrentvpn = "binhex/arch-qbittorrentvpn@sha256:64462c1cef85a4dde9ff76465dfa39f5628b6b88a30143fa48b3546a776fcac0";
        reclaimerr = "ghcr.io/jessielw/reclaimerr@sha256:77e04346352cae25c0beff3c8b63b4c63464e21aab3cca4558c772198fa37540";
        seerr = "ghcr.io/seerr-team/seerr@sha256:f4768de5f616248d723e05891f3345a1402123775d03bf0890dbfedc0831bda1";
        self-service-password = "ltbproject/self-service-password@sha256:9735d99b0b45a3187ff4be5ee0ca1b569ea85cfb2428d9f00c309fdaedfd0142";
        timemachine = "mbentley/timemachine@sha256:2bcbb09008dde4099aa5dcd2ef9884b4c0e6cfdc2247956eac41763b5789b6f1";
        wakapi = "ghcr.io/muety/wakapi@sha256:3f54a3e0f876d7f8182694527d5f50eafd4eb296820f96201ee509a9f9334910";
      };
}
