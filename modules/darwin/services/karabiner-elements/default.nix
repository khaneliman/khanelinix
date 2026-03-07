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

      chmod 4755 '${supportDir}/bin/karabiner_session_monitor'
    '';

    system.activationScripts.postActivation.text = ''
      echo "attempt to activate karabiner system extension and start daemons" >&2
      launchctl unload /Library/LaunchDaemons/org.nixos.start_karabiner_daemons.plist || true
      launchctl load -w /Library/LaunchDaemons/org.nixos.start_karabiner_daemons.plist
    '';
  };
}
