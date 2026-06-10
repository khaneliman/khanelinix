{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    types
    ;

  cfg = config.khanelinix.services.lumen;
  userName = config.khanelinix.user.name;
  userHome = config.users.users.${userName}.home;
  defaultAppsFile = pkgs.writeText "lumen-apps.json" (
    builtins.toJSON {
      env = {
        PATH = "$(PATH):$(HOME)/.local/bin";
      };
      apps = [
        {
          name = "Desktop";
        }
      ];
    }
  );
  defaultConfigFile = pkgs.writeText "lumen-sunshine.conf" ''
    audio_sink = system
    max_bitrate = 80000
    virtual_display = enabled
    upnp = enabled
  '';
in
{
  options.khanelinix.services.lumen = {
    enable = mkEnableOption "Lumen macOS game stream host for Moonlight";

    package = mkPackageOption pkgs.khanelinix "lumen" { };

    autoStart = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to start Lumen automatically through launchd.";
    };

    installDir = mkOption {
      type = types.str;
      default = "${userHome}/.local/share/lumen";
      description = "Stable mutable install directory used for TCC and ad-hoc codesigning.";
    };

    configDir = mkOption {
      type = types.str;
      default = "${userHome}/.config/sunshine";
      description = "Sunshine-compatible configuration directory used by Lumen.";
    };

    logPaths = {
      stdout = mkOption {
        type = types.str;
        default = "${userHome}/Library/Logs/lumen/lumen.out.log";
        description = "Path to Lumen stdout log file.";
      };

      stderr = mkOption {
        type = types.str;
        default = "${userHome}/Library/Logs/lumen/lumen.err.log";
        description = "Path to Lumen stderr log file.";
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    launchd.user.agents.lumen.serviceConfig = {
      ProgramArguments = [ "${cfg.installDir}/sunshine" ];
      RunAtLoad = cfg.autoStart;
      KeepAlive = cfg.autoStart;
      StandardOutPath = cfg.logPaths.stdout;
      StandardErrorPath = cfg.logPaths.stderr;
      WorkingDirectory = cfg.configDir;
    };

    system.activationScripts.extraActivation.text = ''
      echo >&2 "Setting up stable Lumen runtime..."

      install -d -m 0755 -o ${userName} -g staff \
        "${cfg.installDir}" \
        "${cfg.configDir}" \
        "${cfg.configDir}/scripts" \
        "${userHome}/.local/bin" \
        "$(dirname "${cfg.logPaths.stdout}")" \
        "$(dirname "${cfg.logPaths.stderr}")"

      # install -d only chowns directories it creates; repair configDir if an
      # earlier activation left it root-owned (sunshine needs to write here).
      chown ${userName}:staff "${cfg.configDir}"

      install -m 0755 -o ${userName} -g staff "${cfg.package}/libexec/lumen/sunshine" "${cfg.installDir}/sunshine"
      install -m 0755 -o ${userName} -g staff "${cfg.package}/libexec/lumen/vd_helper" "${cfg.installDir}/vd_helper"
      install -m 0755 -o ${userName} -g staff "${cfg.package}/libexec/lumen/get_display_origin" "${cfg.installDir}/get_display_origin"
      install -m 0644 -o ${userName} -g staff "${cfg.package}/share/lumen/hid_entitlements.plist" "${cfg.installDir}/hid_entitlements.plist"

      for script in "${cfg.package}/share/lumen/scripts/"*.sh; do
        install -m 0755 -o ${userName} -g staff "$script" "${cfg.configDir}/scripts/$(basename "$script")"
      done

      printf '%s\n' \
        '#!/bin/sh' \
        'exec "${cfg.installDir}/sunshine" "$@"' \
        > "${userHome}/.local/bin/lumen"
      chown ${userName}:staff "${userHome}/.local/bin/lumen"
      chmod 0755 "${userHome}/.local/bin/lumen"

      if [ ! -f "${cfg.configDir}/sunshine.conf" ]; then
        install -m 0644 -o ${userName} -g staff "${defaultConfigFile}" "${cfg.configDir}/sunshine.conf"
        chown ${userName}:staff "${cfg.configDir}/sunshine.conf"
        chmod 0644 "${cfg.configDir}/sunshine.conf"
      fi

      if [ ! -f "${cfg.configDir}/apps.json" ]; then
        install -m 0644 -o ${userName} -g staff "${defaultAppsFile}" "${cfg.configDir}/apps.json"
        chown ${userName}:staff "${cfg.configDir}/apps.json"
        chmod 0644 "${cfg.configDir}/apps.json"
      fi

      if /usr/sbin/nvram boot-args 2>/dev/null | /usr/bin/grep -q "amfi_get_out_of_my_way=1"; then
        /usr/bin/codesign --sign - --entitlements "${cfg.installDir}/hid_entitlements.plist" --force "${cfg.installDir}/sunshine" 2>/dev/null || true
        /usr/bin/codesign --sign - --force "${cfg.installDir}/vd_helper" 2>/dev/null || true
      fi
    '';
  };
}
