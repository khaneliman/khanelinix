{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib)
    concatStrings
    mapAttrs'
    mapAttrsToList
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    nameValuePair
    types
    ;

  cfg = config.khanelinix.services.lumen;
  userName = config.khanelinix.user.name;
  userHome = config.users.users.${userName}.home;

  formatSettingValue =
    value: if lib.isBool value then if value then "enabled" else "disabled" else toString value;

  defaultSettingsFor = instance: {
    sunshine_name = instance.sunshineName;
    inherit (instance) port;
    audio_sink = "system";
    max_bitrate = 80000;
    virtual_display = instance.virtualDisplay;
    upnp = true;
    file_state = "${instance.configDir}/sunshine_state.json";
    file_apps = "${instance.configDir}/apps.json";
    log_path = "${instance.configDir}/sunshine.log";
    pkey = "${instance.configDir}/credentials/cakey.pem";
    cert = "${instance.configDir}/credentials/cacert.pem";
  };

  settingsFor = instance: (defaultSettingsFor instance) // instance.settings;

  settingsTextFor =
    instance:
    concatStrings (
      mapAttrsToList (key: value: "${key} = ${formatSettingValue value}\n") (settingsFor instance)
    );

  managedSettingsCommandsFor =
    instance:
    concatStrings (
      mapAttrsToList (
        key: value:
        let
          args = lib.escapeShellArgs [
            "${instance.configDir}/sunshine.conf"
            key
            (formatSettingValue value)
          ];
        in
        "    set_lumen_setting ${args}\n"
      ) (settingsFor instance)
    );

  activationFor = name: instance: ''
    install -d -m 0755 -o ${userName} -g staff \
      "${instance.configDir}" \
      "${instance.configDir}/scripts"

    # install -d only chowns directories it creates; repair configDir if an
    # earlier activation left it root-owned (sunshine needs to write here).
    chown ${userName}:staff "${instance.configDir}"

    for script in "${cfg.package}/share/lumen/scripts/"*.sh; do
      install -m 0755 -o ${userName} -g staff "$script" "${instance.configDir}/scripts/$(basename "$script")"
    done

    if [ ! -f "${instance.configDir}/sunshine.conf" ]; then
      install -m 0644 -o ${userName} -g staff "${confFileFor name instance}" "${instance.configDir}/sunshine.conf"
    fi

    ${managedSettingsCommandsFor instance}
    install -m 0644 -o ${userName} -g staff "${appsFileFor name instance}" "${instance.configDir}/apps.json"
  '';

  appsFileFor =
    name: instance:
    pkgs.writeText "lumen-${name}-apps.json" (
      builtins.toJSON {
        env = {
          PATH = "$(PATH):$(HOME)/.local/bin";
        };
        inherit (instance) apps;
      }
    );

  confFileFor =
    name: instance: pkgs.writeText "lumen-${name}-sunshine.conf" (settingsTextFor instance);

  instanceModule =
    { name, ... }:
    {
      options = {
        autoStart = mkOption {
          type = types.bool;
          default = true;
          description = "Whether to start this Lumen instance automatically through launchd.";
        };

        virtualDisplay = mkOption {
          type = types.bool;
          default = true;
          description = "Whether this instance creates an on-demand virtual display (true) or captures and controls the physical display (false).";
        };

        port = mkOption {
          type = types.port;
          default = 47989;
          description = "Base port for this instance. The web UI listens on https://<host>:<port + 1>. Derived ports span base-5 (HTTPS) through base+21 (RTSP), so instances need at least 27 ports of separation.";
        };

        sunshineName = mkOption {
          type = types.str;
          default = "${config.networking.hostName} ${name}";
          description = "Host name advertised to Moonlight clients via mDNS.";
        };

        configDir = mkOption {
          type = types.str;
          default = "${userHome}/.config/sunshine-${name}";
          description = "Sunshine-compatible configuration directory for this instance.";
        };

        apps = mkOption {
          type = types.listOf (types.attrsOf types.anything);
          default = [ { name = "Desktop"; } ];
          description = "Application entries written to this instance's apps.json. Managed declaratively; edits made through the web UI are overwritten on activation.";
        };

        settings = mkOption {
          type = types.attrsOf (
            types.oneOf [
              types.bool
              types.int
              types.path
              types.str
            ]
          );
          default = { };
          description = "Additional sunshine.conf settings for this instance. Values here override module defaults for duplicate keys.";
        };
      };
    };
in
{
  options.khanelinix.services.lumen = {
    enable = mkEnableOption "Lumen macOS game stream host for Moonlight";

    package = mkPackageOption pkgs.khanelinix "lumen" { };

    installDir = mkOption {
      type = types.str;
      default = "${userHome}/.local/share/lumen";
      description = "Stable mutable install directory used for TCC and ad-hoc codesigning.";
    };

    instances = mkOption {
      type = types.attrsOf (types.submodule instanceModule);
      default = { };
      description = "Lumen instances, each advertised as a separate Moonlight host.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    # Ad-hoc signed binary outside /Applications; without an explicit ALF
    # allow entry macOS blocks Moonlight's incoming discovery/session traffic.
    khanelinix.system.networking.applicationFirewall.allowedApps = [
      "${cfg.installDir}/sunshine"
    ];

    launchd.user.agents = mapAttrs' (
      name: instance:
      nameValuePair "lumen-${name}" {
        serviceConfig = {
          # sunshine only reads ~/.config/sunshine/sunshine.conf by default;
          # the working directory is ignored for config discovery.
          ProgramArguments = [
            "${cfg.installDir}/sunshine"
            "${instance.configDir}/sunshine.conf"
          ];
          RunAtLoad = instance.autoStart;
          KeepAlive = instance.autoStart;
          StandardOutPath = "${userHome}/Library/Logs/lumen/${name}.out.log";
          StandardErrorPath = "${userHome}/Library/Logs/lumen/${name}.err.log";
          WorkingDirectory = instance.configDir;
        };
      }
    ) cfg.instances;

    system.activationScripts.extraActivation.text = ''
      echo >&2 "Setting up stable Lumen runtime..."

      install -d -m 0755 -o ${userName} -g staff \
        "${cfg.installDir}" \
        "${userHome}/.local/bin" \
        "${userHome}/Library/Logs/lumen"

      install -m 0755 -o ${userName} -g staff "${cfg.package}/libexec/lumen/sunshine" "${cfg.installDir}/sunshine"
      install -m 0755 -o ${userName} -g staff "${cfg.package}/libexec/lumen/vd_helper" "${cfg.installDir}/vd_helper"
      install -m 0755 -o ${userName} -g staff "${cfg.package}/libexec/lumen/get_display_origin" "${cfg.installDir}/get_display_origin"
      install -m 0644 -o ${userName} -g staff "${cfg.package}/share/lumen/hid_entitlements.plist" "${cfg.installDir}/hid_entitlements.plist"

      printf '%s\n' \
        '#!/bin/sh' \
        'exec "${cfg.installDir}/sunshine" "$@"' \
        > "${userHome}/.local/bin/lumen"
      chown ${userName}:staff "${userHome}/.local/bin/lumen"
      chmod 0755 "${userHome}/.local/bin/lumen"

      set_lumen_setting() {
        file=$1
        key=$2
        value=$3
        tmp="$file.tmp.$$"

        /usr/bin/awk -v key="$key" -v value="$value" '
          BEGIN {
            done = 0
            pattern = "^[[:space:]]*" key "[[:space:]]*="
          }

          $0 ~ pattern {
            if (!done) {
              print key " = " value
              done = 1
            }
            next
          }

          { print }

          END {
            if (!done) {
              print key " = " value
            }
          }
        ' "$file" > "$tmp"

        install -m 0644 -o ${userName} -g staff "$tmp" "$file"
        rm -f "$tmp"
      }

      ${concatStrings (mapAttrsToList activationFor cfg.instances)}

      if /usr/sbin/nvram boot-args 2>/dev/null | /usr/bin/grep -q "amfi_get_out_of_my_way=1"; then
        /usr/bin/codesign --sign - --entitlements "${cfg.installDir}/hid_entitlements.plist" --force "${cfg.installDir}/sunshine" 2>/dev/null || true
        /usr/bin/codesign --sign - --force "${cfg.installDir}/vd_helper" 2>/dev/null || true
      fi
    '';
  };
}
