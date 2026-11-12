{
  config,
  lib,
  ...
}:
let
  cfg = config.services.hermes-agent;
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

  systemd.services.hermes-agent = {
    description = "Hermes gateway with AustinServer state";
    wantedBy = [ "multi-user.target" ];
    requires = [ "user@99.service" ];
    after = [
      "network-online.target"
      "user@99.service"
    ];
    wants = [ "network-online.target" ];
    unitConfig = {
      RequiresMountsFor = [ cfg.stateDir ];
      AssertPathExists = "${cfg.stateDir}/config.yaml";
    };
    path = cfg.extraPackages;
    environment = {
      HOME = cfg.stateDir;
      HERMES_HOME = cfg.stateDir;
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
      ReadWritePaths = [ cfg.stateDir ];
      BindPaths = [ "${cfg.stateDir}:/opt/data" ];
      PrivateTmp = true;
      UMask = "0007";
    };
  };
}
