{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf mkPackageOption;

  cfg = config.services.karabiner-elements;

  packageSupportPath = "${cfg.package}/Library/Application Support/org.pqrs/Karabiner-Elements";
  packageDriverSupportPath = "${cfg.package.driver}/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice";
  supportDir = "/Library/Application Support/org.pqrs/Karabiner-Elements";
  driverSupportDir = "/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice";
  managerAppPath = "/Applications/.Karabiner-VirtualHIDDevice-Manager.app";
  nonPrivilegedAgentsApp = "${supportDir}/Karabiner-Elements Non-Privileged Agents v2.app/Contents/MacOS/Karabiner-Elements Non-Privileged Agents v2";
  privilegedDaemonsApp = "${supportDir}/Karabiner-Elements Privileged Daemons v2.app/Contents/MacOS/Karabiner-Elements Privileged Daemons v2";
  # Records which package deployed the support trees. Refreshing the trees
  # while services run from them breaks Karabiner IPC, so activation must
  # skip the refresh when the package is unchanged.
  packageMarker = "/Library/Application Support/org.pqrs/.khanelinix-karabiner-package";
  # toString maps a null primaryUser to "", which the uid lookups treat as
  # "no user" at runtime.
  primaryUserName = toString config.system.primaryUser;
in
{
  disabledModules = [ "services/karabiner-elements" ];

  options.services.karabiner-elements = {
    enable = mkEnableOption "Karabiner-Elements";
    package = mkPackageOption pkgs "karabiner-elements" { };
  };

  config = mkIf cfg.enable {
    environment = {
      systemPackages = [ cfg.package ];
    };

    launchd = {
      daemons = {
        start_karabiner_daemons = {
          script = ''
            "${managerAppPath}/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager" activate
            "${privilegedDaemonsApp}" register-core-daemons
          '';
          serviceConfig = {
            Label = "org.nixos.start_karabiner_daemons";
            RunAtLoad = true;
          };
        };
      };
      user = {
        agents = {
          register_karabiner_agents = {
            managedBy = "services.karabiner-elements.enable";
            serviceConfig = {
              ProgramArguments = [
                nonPrivilegedAgentsApp
                "register-core-agents"
              ];
              RunAtLoad = true;
            };
          };
        };
      };
    };

    system.activationScripts.preActivation.text = ''
      # Sparkle direct installs split Karabiner across two versions and
      # duplicate service registrations. Nix owns the deployment, so remove
      # imperative copies whenever they reappear.
      for karabinerApp in '/Applications/Karabiner-Elements.app' '/Applications/Karabiner-EventViewer.app'; do
        if [ -d "$karabinerApp" ] && [ ! -L "$karabinerApp" ]; then
          rm -rf "$karabinerApp"
        fi
      done
      pkgutil --forget org.pqrs.Karabiner-Elements > /dev/null 2>&1 || true
      pkgutil --forget org.pqrs.Karabiner-DriverKit-VirtualHIDDevice > /dev/null 2>&1 || true

      # Unload legacy launchd jobs from pre-16 installs and old module
      # revisions. bootout is a no-op when the label is absent; stale
      # enable-override records persist in launchd's database and are inert.
      for label in org.pqrs.karabiner.karabiner_grabber org.pqrs.karabiner.karabiner_observer org.nixos.setsuid_karabiner_session_monitor; do
        launchctl bootout system/"$label" 2> /dev/null || true
      done
      # Activation PATH provides GNU stat; BSD stat owns the -f format flag.
      consoleUserUid=$(/usr/bin/stat -f %u /dev/console || echo 0)
      if [ "$consoleUserUid" != "0" ]; then
        for label in org.pqrs.karabiner.karabiner_session_monitor org.nixos.activate_karabiner_system_ext org.nixos.karabiner_non_privileged_agents_v2; do
          launchctl bootout gui/"$consoleUserUid"/"$label" 2> /dev/null || true
        done
      fi

      # Missing trees also force a refresh; the marker alone cannot see
      # out-of-band deletion or a partially copied tree from an aborted run.
      if [ "$(cat '${packageMarker}' 2> /dev/null)" != '${cfg.package}' ] \
        || [ ! -d '${supportDir}' ] || [ ! -d '${driverSupportDir}' ] || [ ! -d '${managerAppPath}' ]; then
        echo "refreshing karabiner support trees" >&2
        # postActivation keys its reload on a marker mismatch, so a refresh
        # forced by missing trees must clear a matching marker.
        rm -f '${packageMarker}'

        # Stop services before the refresh deletes the trees they run from.
        # Agent registration is per-user, so unregister runs in the primary
        # user's GUI session. Without a session, stale agents exit at logout
        # and register_karabiner_agents re-registers them at next login.
        primaryUserUid=$(id -u '${primaryUserName}' 2> /dev/null || echo 0)
        if [ "$primaryUserUid" != "0" ] && [ -x '${nonPrivilegedAgentsApp}' ]; then
          launchctl asuser "$primaryUserUid" sudo -u "#$primaryUserUid" -- '${nonPrivilegedAgentsApp}' unregister-core-agents || true
        fi
        if [ -x '${privilegedDaemonsApp}' ]; then
          '${privilegedDaemonsApp}' unregister-core-daemons || true
        fi

        rm -rf '${managerAppPath}'
        mkdir -p '/Applications'
        # System extensions must reside inside /Applications and cannot be symlinks.
        cp -R '${cfg.package.driver}/Applications/.Karabiner-VirtualHIDDevice-Manager.app' '${managerAppPath}'

        rm -rf '${supportDir}'
        mkdir -p '/Library/Application Support/org.pqrs'
        cp -R '${packageSupportPath}' '${supportDir}'

        rm -rf '${driverSupportDir}'
        mkdir -p '/Library/Application Support/org.pqrs'
        cp -R '${packageDriverSupportPath}' '${driverSupportDir}'

        # Re-register daemons immediately. An abort later in activation must
        # not leave input remapping down until the next switch.
        '${managerAppPath}/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager' activate || true
        '${privilegedDaemonsApp}' register-core-daemons || true
      fi
    '';

    system.activationScripts.postActivation.text = ''
      if [ "$(cat '${packageMarker}' 2> /dev/null)" != '${cfg.package}' ]; then
        echo "activate karabiner system extension and start daemons" >&2
        launchctl unload /Library/LaunchDaemons/org.nixos.start_karabiner_daemons.plist || true
        launchctl load -w /Library/LaunchDaemons/org.nixos.start_karabiner_daemons.plist

        # Restart agent registration so agents exec from the refreshed tree.
        # Without a GUI session, RunAtLoad repairs this at next login.
        primaryUserUid=$(id -u '${primaryUserName}' 2> /dev/null || echo 0)
        if [ "$primaryUserUid" != "0" ]; then
          launchctl kickstart -k gui/"$primaryUserUid"/org.nixos.register_karabiner_agents 2> /dev/null || true
        fi

        printf '%s' '${cfg.package}' > '${packageMarker}'
      fi

      # SMAppService can drop daemon registration in the unregister/register
      # race inside one activation; a verified live incident left remapping
      # down with the marker written. Repair on every activation.
      if [ -x '${privilegedDaemonsApp}' ] && ! '${privilegedDaemonsApp}' core-daemons-enabled > /dev/null 2>&1; then
        echo "re-registering karabiner core daemons" >&2
        '${privilegedDaemonsApp}' register-core-daemons || true
      fi
    '';
  };
}
