{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.hermes-agent;
  stacks = "/mnt/pool/appdata/compose-projects";
in
{
  # The upstream unit manages stateDir/.hermes. AustinServer has a flat
  # HERMES_HOME, so retain its files and settings without an activation rewrite.
  services.hermes-agent = {
    enable = lib.mkForce false;
    user = "media";
    group = "users";
    createUser = false;
  };
  users.users.media = {
    home = cfg.stateDir;
    linger = true;
  };
  environment.systemPackages = [ cfg.package ];

  virtualisation.oci-containers.containers.hermes-docker-proxy = {
    image = "tecnativa/docker-socket-proxy";
    ports = [ "127.0.0.1:2376:2375" ];
    networks = [ "name=hermes_agent_default,ip=172.20.0.2,alias=HermesDockerProxy" ];
    volumes = [ "/var/run/docker.sock:/var/run/docker.sock:ro" ];
    environment = {
      ALLOW_START = "1";
      ALLOW_STOP = "1";
      ALLOW_RESTARTS = "1";
      AUTH = "0";
      BUILD = "0";
      CONTAINERS = "1";
      DISTRIBUTION = "0";
      EVENTS = "1";
      EXEC = "0";
      IMAGES = "1";
      INFO = "1";
      NETWORKS = "1";
      PING = "1";
      POST = "1";
      PULL = "0";
      PUSH = "0";
      SERVICES = "0";
      SYSTEM = "1";
      TASKS = "0";
      VERSION = "1";
      VOLUMES = "1";
    };
  };
  systemd.services.khanelilab-container-networks.script = lib.mkAfter ''
    ensure_network hermes_agent_default bridge 172.20.0.0/16 172.20.0.1
  '';

  systemd.services.hermes-agent = {
    description = "Hermes gateway with AustinServer state";
    wantedBy = [ "multi-user.target" ];
    requires = [
      "docker-hermes-docker-proxy.service"
      "user@99.service"
    ];
    after = [
      "network-online.target"
      "docker-hermes-docker-proxy.service"
      "user@99.service"
    ];
    wants = [ "network-online.target" ];
    unitConfig = {
      RequiresMountsFor = [
        cfg.stateDir
        stacks
      ];
      AssertPathExists = "${cfg.stateDir}/config.yaml";
      AssertPathIsDirectory = stacks;
    };
    path = cfg.extraPackages ++ [
      pkgs.docker
      pkgs.docker-compose
    ];
    environment = {
      HOME = cfg.stateDir;
      HERMES_HOME = cfg.stateDir;
      DOCKER_HOST = "tcp://127.0.0.1:2376";
      XDG_RUNTIME_DIR = "/run/user/99";
      DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/99/bus";
    };
    serviceConfig = {
      User = cfg.user;
      Group = cfg.group;
      WorkingDirectory = cfg.workingDirectory;
      EnvironmentFile = cfg.environmentFiles;
      ExecStart = "${cfg.package}/bin/hermes gateway";
      Restart = "always";
      RestartSec = 5;
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ReadWritePaths = [
        "/mnt/user/appdata"
        "/mnt/pool/appdata"
      ];
      BindPaths = [
        "${cfg.stateDir}:/opt/data"
        "${stacks}:/opt/stacks"
      ];
      PrivateTmp = true;
      UMask = "0007";
    };
  };
}
