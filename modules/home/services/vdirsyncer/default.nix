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
  davmailTokenFile =
    config.services.davmail.settings."davmail.oauth.tokenFilePath"
      or "${config.xdg.stateHome}/davmail/oauth-tokens.properties";
  davmailAccounts = lib.filterAttrs (
    _name: account: account.enable && account.flavor == "davmail"
  ) config.khanelinix.programs.graphical.apps.thunderbird.extraEmailAccounts;
  vdirsyncerSafeName =
    name:
    let
      allowed = lib.stringToCharacters "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz";
    in
    lib.concatMapStrings (char: if lib.elem char allowed then char else "_") (
      lib.stringToCharacters name
    );
  davmailCalendarAccounts = lib.mapAttrs' (
    name: account: lib.nameValuePair "davmail_${vdirsyncerSafeName name}" account
  ) davmailAccounts;
  davmailPairNames = map (name: "calendar_${name}") (lib.attrNames davmailCalendarAccounts);
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

    davmail.enable = lib.mkEnableOption "DavMail calendar synchronization";
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

        systemd.user.services.vdirsyncer.Service.ExecStart = lib.mkIf pkgs.stdenv.hostPlatform.isLinux (
          lib.mkForce [
            (pkgs.writeShellScript "vdirsyncer-sync-ready-calendars" ''
              set -euo pipefail

              vdirsyncer=${lib.escapeShellArg (lib.getExe config.programs.vdirsyncer.package)}
              pairs=()

              ${lib.optionalString cfg.google.enable ''
                if [ -s ${lib.escapeShellArg googleCalendarTokenFile} ]; then
                  "$vdirsyncer" discover calendar_google_calendars
                  pairs+=(calendar_google_calendars)
                fi
              ''}

              ${lib.optionalString cfg.davmail.enable ''
                if [ -s ${lib.escapeShellArg davmailTokenFile} ]; then
                  for pair in ${lib.escapeShellArgs davmailPairNames}; do
                    "$vdirsyncer" discover "$pair"
                    pairs+=("$pair")
                  done
                fi
              ''}

              if [ "''${#pairs[@]}" -eq 0 ]; then
                exit 0
              fi

              "$vdirsyncer" metasync "''${pairs[@]}"
              "$vdirsyncer" sync "''${pairs[@]}"
            '')
          ]
        );
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

      })

      (lib.mkIf cfg.davmail.enable {
        assertions = [
          {
            assertion = config.khanelinix.services.davmail.enable or false;
            message = "khanelinix.services.vdirsyncer.davmail.enable requires khanelinix.services.davmail.enable.";
          }
          {
            assertion = davmailAccounts != { };
            message = "khanelinix.services.vdirsyncer.davmail.enable requires at least one Thunderbird extraEmailAccounts entry with flavor = \"davmail\".";
          }
          {
            assertion = lib.all (account: (account.passwordCommand or null) != null) (
              lib.attrValues davmailAccounts
            );
            message = "khanelinix.services.vdirsyncer.davmail.enable requires each DavMail extraEmailAccounts entry to set passwordCommand.";
          }
        ];

        accounts.calendar.accounts = lib.mapAttrs (_name: account: {
          remote = {
            type = "caldav";
            url = "http://localhost:1080/users/${account.address}/calendar";
            userName = account.address;
          }
          // lib.optionalAttrs ((account.passwordCommand or null) != null) {
            inherit (account) passwordCommand;
          };

          khal = {
            enable = config.khanelinix.programs.terminal.tools.khal.enable or false;
            readOnly = true;
          };

          vdirsyncer = {
            enable = true;
            collections = null;
            metadata = [
              "color"
              "displayname"
            ];
            timeRange = {
              start = "datetime.now() - timedelta(days=30)";
              end = "datetime.now() + timedelta(days=180)";
            };
          };
        }) davmailCalendarAccounts;

        home.activation.vdirsyncerDavmailCalendarCollections = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          $DRY_RUN_CMD ${lib.getExe' pkgs.coreutils "mkdir"} -p ${
            lib.escapeShellArgs (
              lib.mapAttrsToList (
                name: _account: "${config.xdg.dataHome}/calendars/${name}"
              ) davmailCalendarAccounts
            )
          }
        '';

        systemd.user.services.vdirsyncer = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
          Unit = {
            After = [ "davmail.service" ];
            Wants = [ "davmail.service" ];
          };

        };
      })
    ]
  );
}
