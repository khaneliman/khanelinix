{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.system.networking;
in
{
  options.khanelinix.system.networking = {
    enable = lib.mkEnableOption "networking support";
  };

  config = mkIf cfg.enable {
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

    # Nix store/build paths rotate often, so stale ALF app rules can accumulate.
    system.activationScripts.applicationFirewallCleanup.text = /* Bash */ ''
      alf="/usr/libexec/ApplicationFirewall/socketfilterfw"
      if [ ! -x "$alf" ]; then
        exit 0
      fi

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
    '';
  };
}
