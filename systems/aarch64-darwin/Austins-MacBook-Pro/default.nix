{lib, ...}:
with lib.internal; {
  khanelinix = {
    suites = {
      art = enabled;
      common = enabled;
      desktop = enabled;
      development = enabled;
    };
  };

  environment.systemPath = [
    "/opt/homebrew/bin"
  ];

  system.stateVersion = 4;
}
