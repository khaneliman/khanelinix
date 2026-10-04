{
  config,
  lib,
  pkgs,

  ...
}:
let
  cfg = config.khanelinix.system.networking;
  homeCfg = config.home-manager.users.${config.khanelinix.user.name} or { };
  exoEnabled = homeCfg.services.exo.enable or false;
  exoLibp2pPort = 52416;
  syncthingEnabled = homeCfg.services.syncthing.enable or false;
  # Use the package instance from the user's Home Manager service so the
  # allowlisted path matches the binary the LaunchAgent launches.
  syncthingPackage = homeCfg.services.syncthing.package or pkgs.syncthing;
  # Use the package instance from the user's home packages so the allowlisted
  # path matches what actually launches (overlays could diverge from pkgs here).
  moonlightPackage = lib.findFirst (p: lib.getName p == "moonlight-qt") null (
    homeCfg.home.packages or [ ]
  );
  applicationFirewallAllowedApps =
    cfg.applicationFirewall.allowedApps
    ++ lib.optionals exoEnabled [
      "${pkgs.exo}/bin/exo"
      # exo's bin/exo is a shell wrapper that execs the bare interpreter, so
      # ALF tracks python itself. The exo overlay pins its own interpreter
      # (MLX wheel constraint), so read it from the package, not pkgs.python3.
      "${pkgs.exo.python.interpreter}"
    ]
    ++ lib.optionals syncthingEnabled [
      (lib.getExe syncthingPackage)
    ]
    ++ lib.optionals (moonlightPackage != null) [
      # ALF tracks the real listening executable, not the qt wrapper script.
      "${moonlightPackage}/Applications/Moonlight.app/Contents/MacOS/.Moonlight-wrapped"
    ];
  applicationFirewallAllowedAppsFile = pkgs.writeText "khanelinix-alf-allowed-apps" (
    lib.concatMapStrings (app: app + "\n") applicationFirewallAllowedApps
  );
in
{
  options.khanelinix.system.networking = {
    enable = lib.mkEnableOption "networking support";
    applicationFirewall.allowedApps = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Absolute paths to applications that should be allowed through the macOS Application Firewall during activation.";
    };
  };

  config = lib.mkIf cfg.enable {
    networking = {
      applicationFirewall = {
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
      # nix-darwin runs `defaults write` from `/`, and a slash in the domain
      # makes `defaults` treat it as a filesystem path, so the domain must be
      # absolute to land in /Library/Preferences.
      defaults.CustomSystemPreferences = {
        "/Library/Preferences/SystemConfiguration/com.apple.captive.control" = {
          Active = false;
        };
      };

      activationScripts.networking.text = lib.mkAfter ''
        alf="/usr/libexec/ApplicationFirewall/socketfilterfw"

        echo >&2 "Auditing Application Firewall entries..."

        if [ ! -x "$alf" ]; then
          echo >&2 "Skipping Application Firewall audit: socketfilterfw is unavailable."
        else
          applicationFirewallAllowedApps="${applicationFirewallAllowedAppsFile}"
          backupDir="/var/backups/khanelinix-alf"

          "$alf" --listapps \
            | /usr/bin/sed -n 's/^[[:space:]]*[0-9][0-9]*[[:space:]]:[[:space:]]//p' \
            | /usr/bin/sed 's/[[:space:]]*$//' \
            | while IFS= read -r app; do
                keepApp=false
                while IFS= read -r allowedApp; do
                  if [ "$app" = "$allowedApp" ]; then
                    keepApp=true
                    break
                  fi
                done < "$applicationFirewallAllowedApps"

                if [ "$keepApp" = true ]; then
                  continue
                fi

                case "$app" in
                  /nix/store/*|/nix/var/nix/*|/private/tmp/nix-build*)
                    # Existing executables may have permissions managed outside
                    # this allowlist, including services from older generations.
                    if [ ! -e "$app" ]; then
                      "$alf" --remove "$app" >/dev/null 2>&1 || true
                    fi
                    ;;
                esac
              done

          while IFS= read -r allowedApp; do
            if [ -e "$allowedApp" ]; then
              resolvedApp="$(${lib.getExe' pkgs.coreutils "readlink"} -f "$allowedApp")"
              case "$resolvedApp" in
                /nix/store/*)
                  if [ -f "$resolvedApp" ] && [ "$(/usr/bin/stat -f %l "$resolvedApp")" -gt 1 ]; then
                    indexHash="$("${lib.getExe' config.nix.package "nix"}" hash path --type sha256 --base32 "$resolvedApp")"
                    indexPath="/nix/store/.links/$indexHash"
                    if [ -f "$indexPath" ] && [ ! -L "$indexPath" ] \
                      && [ "$(/usr/bin/stat -f '%d:%i' "$resolvedApp")" = "$(/usr/bin/stat -f '%d:%i' "$indexPath")" ]; then
                      # Remove only the optimiser's alias, not the store file.
                      # ALF otherwise scans .links during code identity discovery.
                      /usr/bin/install -d -m 0700 -o root -g wheel "$backupDir"
                      if ! /usr/bin/cmp -s "$indexPath" "$backupDir/$indexHash"; then
                        backupTmp="$(/usr/bin/mktemp "$backupDir/.$indexHash.XXXXXX")"
                        if ! /bin/cp "$indexPath" "$backupTmp" \
                          || ! /usr/bin/cmp -s "$indexPath" "$backupTmp"; then
                          /bin/rm -f "$backupTmp"
                          echo >&2 "Failed to back up optimiser index entry for $allowedApp"
                          exit 1
                        fi
                        /bin/mv -f "$backupTmp" "$backupDir/$indexHash"
                      fi
                      /usr/bin/cmp "$indexPath" "$backupDir/$indexHash"
                      # Persist the restart until it succeeds, even if activation
                      # stops after unlinking or the firewall cannot be restarted.
                      /usr/bin/touch "$backupDir/restart-needed"
                      /bin/rm -f "$indexPath"
                      echo >&2 "Removed backed-up optimiser index entry for $allowedApp"
                    fi
                  fi
                  ;;
              esac
              "$alf" --add "$allowedApp" >/dev/null 2>&1 || true
              "$alf" --unblockapp "$allowedApp" >/dev/null 2>&1 || true
            else
              echo >&2 "Skipping missing Application Firewall app: $allowedApp"
            fi
          done < "$applicationFirewallAllowedApps"

          if [ -e "$backupDir/restart-needed" ]; then
            # A queued identity lookup can remain stuck after unlinking its alias.
            /usr/bin/killall socketfilterfw
            /bin/rm -f "$backupDir/restart-needed"
          fi
        fi

        anchorName="khanelinix-exo"
        anchorFile="/etc/pf.anchors/$anchorName"
        pfConf="/etc/pf.conf"
        anchorLine="anchor \"$anchorName\""
        loadLine="load anchor \"$anchorName\" from \"$anchorFile\""

        ${lib.optionalString exoEnabled ''
          echo >&2 "Configuring PF rules for exo ports..."

          /usr/bin/install -d -m 0755 -o root -g wheel /etc/pf.anchors
          /usr/bin/printf '%s\n' \
            "# Allow exo's fixed libp2p port and MLX Ring's random high TCP ports on trusted private IPv4 networks." \
            "pass in inet proto tcp from { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 } to any port ${toString exoLibp2pPort}" \
            "pass in inet proto tcp from { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 } to any port 49153:65535" \
            > "$anchorFile.tmp"
          /usr/bin/install -m 0644 -o root -g wheel "$anchorFile.tmp" "$anchorFile"
          /bin/rm -f "$anchorFile.tmp"

          if ! /usr/bin/grep -qxF "$anchorLine" "$pfConf"; then
            /usr/bin/printf '\n%s\n%s\n' "$anchorLine" "$loadLine" >> "$pfConf"
          elif ! /usr/bin/grep -qxF "$loadLine" "$pfConf"; then
            /bin/echo "$loadLine" >> "$pfConf"
          fi

          /sbin/pfctl -f "$pfConf" || echo >&2 "Warning: failed to reload PF configuration."
          /sbin/pfctl -E >/dev/null 2>&1 || true
        ''}

        ${lib.optionalString (!exoEnabled) ''
          if [ -f "$anchorFile" ]; then
            echo >&2 "Removing PF rules for exo MLX ring ports..."
            /bin/rm -f "$anchorFile"
          fi

          if [ -f "$pfConf" ] && /usr/bin/grep -qF "$anchorName" "$pfConf"; then
            tempPfConf="$(/usr/bin/mktemp /tmp/khanelinix-pf.XXXXXX)"
            /usr/bin/grep -vxF "$anchorLine" "$pfConf" \
              | /usr/bin/grep -vxF "$loadLine" > "$tempPfConf"
            /usr/bin/install -m 0644 -o root -g wheel "$tempPfConf" "$pfConf"
            /bin/rm -f "$tempPfConf"
            /sbin/pfctl -f "$pfConf" || echo >&2 "Warning: failed to reload PF configuration."
          fi
        ''}
      '';
    };
  };
}
