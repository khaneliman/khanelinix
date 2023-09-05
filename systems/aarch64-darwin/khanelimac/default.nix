{ lib, ... }:
let
  inherit (lib.internal) enabled;
in
{
  khanelinix = {
    archetypes = {
      personal = enabled;
      workstation = enabled;
    };

    suites = {
      art = enabled;
      business = enabled;
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

  environment.systemPath = [
    "/opt/homebrew/bin"
  ];

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

  system.stateVersion = 4;
}
