{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.khanelinix.services.vdirsyncer;
  googleCalendarLocalPath = "${config.xdg.dataHome}/calendars/google_calendars";
  googleCalendarTokenFile = "${config.xdg.stateHome}/vdirsyncer/google-calendar-token";
in
{
  options.khanelinix.services.vdirsyncer = {
    enable = lib.mkEnableOption "vdirsyncer";

    google = {
      enable = lib.mkEnableOption "Google Calendar synchronization";

      collections = lib.mkOption {
        type = lib.types.listOf (
          lib.types.submodule {
            options = {
              name = lib.mkOption {
                type = lib.types.str;
                description = "vdirsyncer collection display name.";
              };

              remote = lib.mkOption {
                type = lib.types.str;
                description = "Remote Google calendar collection identifier.";
              };

              local = lib.mkOption {
                type = lib.types.str;
                description = "Local vdir collection directory name.";
              };
            };
          }
        );
        default = [ ];
        description = "Google calendar collections to synchronize.";
      };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        accounts.calendar.basePath = "${config.xdg.dataHome}/calendars";

        programs.vdirsyncer.enable = true;

        services.vdirsyncer = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
          enable = true;
          frequency = "*:0/15";
        };
      }

      (lib.mkIf cfg.google.enable {
        assertions = [
          {
            assertion = config.khanelinix.services.sops.enable or false;
            message = "khanelinix.services.vdirsyncer.google.enable requires khanelinix.services.sops.enable.";
          }
          {
            assertion = cfg.google.collections != [ ];
            message = "khanelinix.services.vdirsyncer.google.enable requires khanelinix.services.vdirsyncer.google.collections.";
          }
        ];

        accounts.calendar.accounts.google_calendars = {
          local.path = googleCalendarLocalPath;

          remote = {
            type = "google_calendar";
          };

          thunderbird.enable = false;

          khal = {
            enable = config.khanelinix.programs.terminal.tools.khal.enable or false;
            readOnly = true;
            type = "discover";
          };

          vdirsyncer = {
            enable = true;
            collections = map (collection: [
              collection.name
              collection.remote
              collection.local
            ]) cfg.google.collections;
            metadata = [
              "color"
              "displayname"
            ];
            timeRange = {
              start = "datetime.now() - timedelta(days=30)";
              end = "datetime.now() + timedelta(days=180)";
            };
            tokenFile = googleCalendarTokenFile;
            clientIdCommand = [
              (lib.getExe' pkgs.coreutils "cat")
              config.sops.secrets."calendar/google-client-id".path
            ];
            clientSecretCommand = [
              (lib.getExe' pkgs.coreutils "cat")
              config.sops.secrets."calendar/google-client-secret".path
            ];
          };
        };

        home.activation.vdirsyncerGoogleCalendarCollections = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          $DRY_RUN_CMD ${lib.getExe' pkgs.coreutils "mkdir"} -p ${
            lib.escapeShellArgs (
              map (collection: "${googleCalendarLocalPath}/${collection.local}") cfg.google.collections
            )
          }
        '';

        sops.secrets = {
          "calendar/google-client-id" = {
            sopsFile = lib.getFile "secrets/khaneliman/default.yaml";
          };
          "calendar/google-client-secret" = {
            sopsFile = lib.getFile "secrets/khaneliman/default.yaml";
          };
        };

        systemd.user.services.vdirsyncer.Service.ExecStartPre = lib.mkIf pkgs.stdenv.hostPlatform.isLinux [
          (pkgs.writeShellScript "vdirsyncer-discover-google-calendars" ''
            set -euo pipefail

            token_file=${lib.escapeShellArg googleCalendarTokenFile}

            if [ -s "$token_file" ]; then
              exec ${lib.getExe config.programs.vdirsyncer.package} discover calendar_google_calendars
            fi
          '')
        ];
      })
    ]
  );
}
