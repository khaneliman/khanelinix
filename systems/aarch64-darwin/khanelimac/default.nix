{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) enabled;

  cfg = config.${namespace}.user;
in
{
  khanelinix = {
    archetypes = {
      personal = enabled;
      workstation = enabled;
    };

    security = {
      sops = enabled;
    };

    suites = {
      art = enabled;
      common = enabled;
      desktop = enabled;
      development = enabled;
      games = enabled;
      music = enabled;
      networking = enabled;
      social = enabled;
      video = enabled;
      vm = enabled;
    };

    tools.homebrew.masEnable = true;
  };

  environment.systemPath = [ "/opt/homebrew/bin" ];

  networking = {
    computerName = "Austins MacBook Pro";
    hostName = "khanelimac";
    localHostName = "khanelimac";

    knownNetworkServices = [
      "ThinkPad TBT 3 Dock"
      "Wi-Fi"
      "Thunderbolt Bridge"
    ];
  };

  security.pam.enableSudoTouchIdAuth = true;

  users.users.${cfg.name} = {
    openssh = {
      authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEpfTVxQKmkAYOrsnroZoTk0LewcBIC4OjlsoJY6QbB0"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM7UBwfd7+K0mdkAIb2TE6RzMu6L4wZnG/anuoYqJMPB"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFuMXeT21L3wnxnuzl0rKuE5+8inPSi8ca/Y3ll4s9pC"
      ];
    };
  };

  system.stateVersion = 4;
}
