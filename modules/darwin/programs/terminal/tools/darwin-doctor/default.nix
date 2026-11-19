{
  config,
  lib,
  pkgs,

  ...
}:
let
  cfg = config.khanelinix.programs.terminal.tools.darwin-doctor;
  userName = config.khanelinix.user.name;
  homeConfig = lib.khanelinix.hmUserConfig config;
  primaryUser = config.system.primaryUser;
  development = config.khanelinix.suites.development;
  hardening = config.khanelinix.security.hardening;
  timeMachine = config.khanelinix.services.time-machine;
  userDefaults = homeConfig.khanelinix.system.darwin-defaults or { };
  stableBinaries = homeConfig.khanelinix.system.tcc.stableBinaries or { };
  brewfile = pkgs.writeText "Brewfile" config.homebrew.brewfile;
  persistentAgents = lib.pipe (homeConfig.launchd.agents or { }) [
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
        inherit userName;
        inherit (agent) domain;
        inherit (agent.config) Label;
      }
    ))
  ];
  nativeJobs =
    domain: services: files:
    lib.pipe services [
      (lib.filterAttrs (
        _: job:
        let
          label = job.serviceConfig.Label;
        in
        files."${label}.plist".enable && job.serviceConfig.Disabled != true
      ))
      (lib.mapAttrsToList (
        _: job:
        {
          inherit domain;
          inherit (job.serviceConfig) Label;
        }
        // lib.optionalAttrs (domain != "system") { userName = primaryUser; }
      ))
    ];
  systemDefaults = config.system.defaults;
  softwareUpdateDomain = "/Library/Preferences/com.apple.SoftwareUpdate";
  managedPreferences =
    domain: values:
    lib.mapAttrsToList (key: value: { inherit domain key value; }) (
      lib.filterAttrs (_: value: value != null) values
    );
  hardeningPreferences =
    lib.optionals (hardening.enable && hardening.updates.enable) (
      managedPreferences softwareUpdateDomain (
        lib.getAttrs [
          "AutomaticCheckEnabled"
          "AutomaticDownload"
          "ConfigDataInstall"
          "CriticalUpdateInstall"
          "ScheduleFrequency"
        ] systemDefaults.CustomSystemPreferences.${softwareUpdateDomain}
        // {
          inherit (systemDefaults.SoftwareUpdate) AutomaticallyInstallMacOSUpdates;
        }
      )
    )
    ++ lib.optionals (hardening.enable && hardening.loginWindow.enable) (
      managedPreferences "/Library/Preferences/com.apple.loginwindow" {
        inherit (systemDefaults.loginwindow) DisableConsoleAccess SHOWFULLNAME;
      }
    )
    ++ lib.optionals (hardening.enable && hardening.screenLock.enable) (
      managedPreferences "com.apple.screensaver" {
        inherit (systemDefaults.screensaver) askForPassword askForPasswordDelay;
      }
    );
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
      launchAgents = lib.unique (
        persistentAgents
        ++ nativeJobs "gui" config.launchd.agents config.environment.launchAgents
        ++ nativeJobs "gui" config.launchd.user.agents config.environment.userLaunchAgents
      );
      launchDaemons = nativeJobs "system" config.launchd.daemons config.environment.launchDaemons;
      preferences = lib.optionals (userDefaults.enable or false) preferences ++ hardeningPreferences;
      securityAudit = lib.optionalAttrs (
        hardening.enable && hardening.audit.enable
      ) hardening.audit.expected;
      tccSigning = lib.optionalAttrs (stableBinaries != { }) {
        certificate = "/var/db/khanelinix/tcc-signing/cert.pem";
        openssl = lib.getExe pkgs.openssl;
        binaries = lib.mapAttrs (_: binary: binary.path) stableBinaries;
      };
      rosettaBuilder = lib.optionalAttrs (config.nix-rosetta-builder.enable or false) {
        machinesFile = "/etc/nix/machines";
        # Use nix-darwin's rendered row, including the effective job limit.
        machine = lib.findFirst (
          line: builtins.match "([^[:space:]]*://)?([^[:space:]]*@)?rosetta-builder[[:space:]].*" line != null
        ) null (lib.splitString "\n" (config.environment.etc."nix/machines".text or ""));
      };
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
