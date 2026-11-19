{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.khanelinix.services.notify-failure;
  notify = pkgs.writeShellScript "notify-failure" ''
    set -eu
    payload=$(${lib.getExe pkgs.jq} -cn \
      --arg host ${lib.escapeShellArg config.networking.hostName} \
      --arg unit "$1" '{host: $host, unit: $unit, status: "failed"}')
    # Expand the URL inside curl so it stays out of process arguments and logs.
    if status=$(${lib.getExe pkgs.curl} --disable --silent --globoff --output /dev/null \
      --proto '=https' --max-time 15 --json "$payload" --write-out '%{http_code}' \
      --variable "webhook@$CREDENTIALS_DIRECTORY/webhook-url" \
      --expand-url '{{webhook:trim}}'); then
      case "$status" in 2??) exit 0 ;; esac
    fi
    echo "Could not deliver failure notification for $1." >&2
    exit 1
  '';
in
{
  options.khanelinix.services.notify-failure = {
    webhookUrlFile = lib.mkOption {
      type = lib.types.nullOr lib.types.externalPath;
      default = null;
      description = ''
        Absolute runtime path (for example, a decrypted SOPS file) containing
        an HTTPS webhook URL. The endpoint must accept a JSON POST with host,
        unit and status fields. Leave unset to disable failure notifications.
      '';
    };

    units = lib.mkOption {
      type = lib.types.listOf (lib.types.strMatching "[A-Za-z0-9:_.@-]+[.]service");
      default = [ ];
      description = "Existing systemd service names to notify on failure, including the .service suffix.";
    };
  };

  config = lib.mkIf (cfg.webhookUrlFile != null) {
    systemd.services =
      lib.genAttrs (map (lib.removeSuffix ".service") cfg.units) (_: {
        onFailure = [ "notify-failure@%n.service" ];
      })
      // {
        "notify-failure@" = {
          description = "Send failure notification for %i";
          wants = [ "network-online.target" ];
          after = [ "network-online.target" ];
          serviceConfig = {
            Type = "oneshot";
            DynamicUser = true;
            LoadCredential = "webhook-url:${lib.replaceStrings [ "%" ] [ "%%" ] (toString cfg.webhookUrlFile)}";
            ExecStart = "${notify} %i";
          };
        };
      };
  };
}
