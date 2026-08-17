{
  config,
  lib,
  pkgs,

  ...
}:
let
  cfg = config.khanelinix.programs.terminal.tools.darwin-doctor;
  userName = config.khanelinix.user.name;
  homeConfig = config.home-manager.users.${userName};
  development = config.khanelinix.suites.development;
  timeMachine = config.khanelinix.services.time-machine;
  userDefaults = homeConfig.khanelinix.system.darwin-defaults;
  brewfile = pkgs.writeText "Brewfile" config.homebrew.brewfile;
  persistentAgents = lib.pipe homeConfig.launchd.agents [
    (lib.filterAttrs (
      _name: agent:
      let
        keepAlive = agent.config.KeepAlive or null;
      in
      agent.enable
      && ((agent.config.RunAtLoad or null) == true || keepAlive == true || lib.isAttrs keepAlive)
    ))
    (lib.mapAttrsToList (
      _name: agent: {
        inherit (agent) domain;
        inherit (agent.config) Label;
      }
    ))
  ];
  preferences = [
    {
      domain = "NSGlobalDomain";
      key = "NSAutomaticInlinePredictionEnabled";
      value = userDefaults.inlinePrediction;
    }
    {
      domain = "NSGlobalDomain";
      key = "NSNavPanelExpandedStateForSaveMode";
      value = userDefaults.expandSavePanels;
    }
    {
      domain = "NSGlobalDomain";
      key = "NSNavPanelExpandedStateForSaveMode2";
      value = userDefaults.expandSavePanels;
    }
    {
      domain = "com.apple.desktopservices";
      key = "DSDontWriteNetworkStores";
      value = userDefaults.preventNetworkDsStore;
    }
    {
      domain = "com.apple.desktopservices";
      key = "DSDontWriteUSBStores";
      value = userDefaults.preventUsbDsStore;
    }
  ];
  specification = pkgs.writeText "darwin-doctor.json" (
    builtins.toJSON {
      inherit userName;
      development = {
        inherit (development) containerBackend developerDirectory devToolsSecurity;
        enabled = development.enable;
      };
      homebrew = {
        inherit brewfile;
        enabled = config.homebrew.enable;
      };
      launchAgents = persistentAgents;
      preferences = lib.optionals userDefaults.enable preferences;
      timeMachine = {
        inherit (timeMachine) exclusions expectedDestination;
        enabled = timeMachine.enable;
      };
    }
  );
  doctor = pkgs.writers.writePython3Bin "darwin-doctor" {
    flakeIgnore = [ "E501" ];
  } (builtins.readFile ./doctor.py);
in
{
  options.khanelinix.programs.terminal.tools.darwin-doctor.enable =
    lib.mkEnableOption "report-only Darwin workstation doctor";

  config = lib.mkIf cfg.enable {
    environment.etc."khanelinix/darwin-doctor.json".source = specification;
    environment.systemPackages = [ doctor ];
  };
}
