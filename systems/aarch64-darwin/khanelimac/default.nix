{ lib, ... }:
with lib.internal; {
  khanelinix = {
    tools.homebrew.masEnable = true;

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
