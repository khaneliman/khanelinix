{
  config,
  lib,
  pkgs,

  ...
}:
let
  cfg = config.khanelinix.system.networking;
  python3 = lib.getExe pkgs.python3;
  localNetworkPrivilegesCleanup = ./local-network-privileges-cleanup.py;
in
{
  options.khanelinix.system.networking = {
    enable = lib.mkEnableOption "networking support";
  };

  config = lib.mkIf cfg.enable {
    networking = {
      applicationFirewall = {
        # If socketfilterfw starts consuming high CPU or causes system stutters/WindowServer crashes, you can:
        # 1. Temporarily disable the firewall: sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate off
        # 2. Kill the stuck process: sudo killall socketfilterfw
        # 3. Nuke the corrupted database and restart: sudo rm /Library/Preferences/com.apple.alf.plist && sudo killall socketfilterfw
        enable = true;

        allowSigned = true;
        allowSignedApp = true;
        blockAllIncoming = false;
        enableStealthMode = false;
      };

      dns = [
        "1.1.1.1"
        "1.0.0.1"
        "2606:4700:4700::1111"
        "2606:4700:4700::1001"
      ];
    };

    system = {
      defaults.CustomSystemPreferences = {
        "SystemConfiguration/com.apple.captive.control" = {
          Active = false;
        };
      };

      activationScripts.networking.text = lib.mkAfter /* Bash */ ''
        alf="/usr/libexec/ApplicationFirewall/socketfilterfw"

        echo >&2 "Auditing Application Firewall entries..."

        if [ ! -x "$alf" ]; then
          echo >&2 "Skipping Application Firewall audit: socketfilterfw is unavailable."
        else
          "$alf" --listapps \
            | /usr/bin/sed -n 's/^[[:space:]]*[0-9][0-9]*[[:space:]]:[[:space:]]//p' \
            | /usr/bin/sed 's/[[:space:]]*$//' \
            | while IFS= read -r app; do
                case "$app" in
                  /nix/store/*|/nix/var/nix/*|/private/tmp/nix-build*)
                    "$alf" --remove "$app" >/dev/null 2>&1 || true
                    ;;
                esac
              done
        fi

        networkExtensionPlist="/Library/Preferences/com.apple.networkextension.plist"
        networkExtensionUuidCache="/Library/Preferences/com.apple.networkextension.uuidcache.plist"

        echo >&2 "Auditing Local Network permission entries..."

        if [ ! -f "$networkExtensionPlist" ] || [ ! -f "$networkExtensionUuidCache" ]; then
          echo >&2 "Skipping Local Network permission audit: required NetworkExtension plists are missing."
        else
          tempDir="$(/usr/bin/mktemp -d /tmp/khanelinix-local-network.XXXXXX)"

          export KHANELINIX_NETWORK_EXTENSION_PLIST="$networkExtensionPlist"
          export KHANELINIX_NETWORK_EXTENSION_UUID_CACHE="$networkExtensionUuidCache"
          export KHANELINIX_NETWORK_EXTENSION_PLIST_OUT="$tempDir/com.apple.networkextension.plist"
          export KHANELINIX_NETWORK_EXTENSION_UUID_CACHE_OUT="$tempDir/com.apple.networkextension.uuidcache.plist"
          export KHANELINIX_NETWORK_EXTENSION_CHANGED="$tempDir/changed"
          export KHANELINIX_NETWORK_EXTENSION_SUMMARY="$tempDir/summary"

          "${python3}" "${localNetworkPrivilegesCleanup}"

          summary="$(
            /bin/cat "$KHANELINIX_NETWORK_EXTENSION_SUMMARY" 2>/dev/null \
              || /bin/echo "Local Network permission audit completed without a summary."
          )"

          if [ "$(/bin/cat "$KHANELINIX_NETWORK_EXTENSION_CHANGED" 2>/dev/null || true)" != "1" ]; then
            echo >&2 "$summary"
          else
            echo >&2 "Cleaning stale Local Network permission entries..."
            /usr/bin/install -m 0644 -o root -g wheel \
              "$KHANELINIX_NETWORK_EXTENSION_PLIST_OUT" \
              "$networkExtensionPlist"
            /usr/bin/install -m 0644 -o root -g wheel \
              "$KHANELINIX_NETWORK_EXTENSION_UUID_CACHE_OUT" \
              "$networkExtensionUuidCache"
            echo >&2 "$summary"
          fi

          /bin/rm -rf "$tempDir"
        fi
      '';
    };
  };
}
