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
  vdirsyncerStateDir = "${config.xdg.stateHome}/vdirsyncer";
  davmailTokenFile =
    config.services.davmail.settings."davmail.oauth.tokenFilePath"
      or "${config.xdg.stateHome}/davmail/oauth-tokens.properties";
  davmailFailureStamp = "${vdirsyncerStateDir}/davmail-failed";
  davmailLastSuccess = "${vdirsyncerStateDir}/davmail-last-success";
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

  vdirsyncer = lib.getExe config.programs.vdirsyncer.package;
  googleSync = pkgs.writeShellScript "vdirsyncer-google-sync" ''
    set -euo pipefail

    if [ ! -s ${lib.escapeShellArg googleCalendarTokenFile} ]; then
      echo "Google Calendar token missing; skipping synchronization" >&2
      exit 0
    fi

    ${vdirsyncer} metasync calendar_google_calendars
    ${vdirsyncer} sync calendar_google_calendars
  '';
  davmailReady = pkgs.writeShellScript "wait-for-davmail-caldav" ''
    set -euo pipefail

    for _attempt in {1..30}; do
      if ${lib.getExe pkgs.netcat-openbsd} -z 127.0.0.1 1080; then
        exit 0
      fi
      ${lib.getExe' pkgs.coreutils "sleep"} 1
    done

    echo "DavMail CalDAV endpoint did not become ready" >&2
    exit 1
  '';
  davmailSync = pkgs.writeShellScript "vdirsyncer-davmail-sync" ''
    set -euo pipefail

    if [ ! -s ${lib.escapeShellArg davmailTokenFile} ]; then
      echo "Work calendar authentication missing; run work-calendar-auth" >&2
      exit 1
    fi

    ${vdirsyncer} metasync ${lib.escapeShellArgs davmailPairNames}
    ${vdirsyncer} sync ${lib.escapeShellArgs davmailPairNames}
  '';
  davmailFailureNotify = pkgs.writeShellScript "vdirsyncer-davmail-failure-notify" ''
    set -euo pipefail

    ${lib.getExe' pkgs.systemd "systemctl"} --user stop vdirsyncer-davmail.timer
    ${lib.getExe' pkgs.coreutils "install"} -m 0600 /dev/null ${lib.escapeShellArg davmailFailureStamp}
    ${lib.getExe pkgs.libnotify} -a "Work Calendar" -u critical \
      "Work calendar sync paused" \
      "Run work-calendar-auth to repair authentication and resume sync." \
      >/dev/null 2>&1 || true
  '';
  workCalendarAuth = pkgs.writeShellApplication {
    name = "work-calendar-auth";
    runtimeInputs = [
      config.programs.vdirsyncer.package
      pkgs.systemd
    ];
    text = ''
      journal_pid=""
      restart_timer=false

      cleanup() {
        if [[ -n "$journal_pid" ]]; then
          kill "$journal_pid" >/dev/null 2>&1 || true
        fi
        if [[ "$restart_timer" == true ]]; then
          systemctl --user start vdirsyncer-davmail.timer
        fi
      }
      trap cleanup EXIT

      printf '%s\n' \
        "Close Thunderbird before enrollment to avoid competing device-code flows." \
        "Ensure every saved localhost DavMail password matches the SOPS work-password." \
        "Press Enter to continue."
      read -r _

      systemctl --user stop vdirsyncer-davmail.timer vdirsyncer-davmail.service
      systemctl --user start davmail.service

      journalctl --user --unit=davmail.service --since=now --follow --output=cat &
      journal_pid=$!

      pairs=(${lib.escapeShellArgs davmailPairNames})
      for pair in "''${pairs[@]}"; do
        vdirsyncer discover "$pair"
      done

      systemctl --user start vdirsyncer-davmail.service
      restart_timer=true
    '';
  };
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

        home.activation.vdirsyncerState = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          $DRY_RUN_CMD ${lib.getExe' pkgs.coreutils "install"} -d -m 0700 ${lib.escapeShellArg vdirsyncerStateDir}
        '';

        systemd.user.servicesStartTimeoutMs = lib.mkDefault 240000;
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
          $DRY_RUN_CMD ${lib.getExe' pkgs.coreutils "install"} -d -m 0700 ${
            lib.escapeShellArgs (
              map (collection: "${googleCalendarLocalPath}/${collection.local}") cfg.google.collections
            )
          }
        '';

        systemd.user = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
          services.vdirsyncer-google = {
            Unit = {
              Description = "Google Calendar synchronization";
              "X-SwitchMethod" = "keep-old";
            };

            Service = {
              Type = "oneshot";
              ExecStart = [ googleSync ];
              TimeoutStartSec = "3m";
              UMask = "0077";
            };
          };

          timers.vdirsyncer-google = {
            Unit.Description = "Google Calendar synchronization";
            Timer = {
              OnCalendar = "*:0/15";
              Persistent = true;
              Unit = "vdirsyncer-google.service";
            };
            Install.WantedBy = [ "timers.target" ];
          };
        };

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
          $DRY_RUN_CMD ${lib.getExe' pkgs.coreutils "install"} -d -m 0700 ${
            lib.escapeShellArgs (
              lib.mapAttrsToList (
                name: _account: "${config.xdg.dataHome}/calendars/${name}"
              ) davmailCalendarAccounts
            )
          }
        '';

        systemd.user = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
          services = {
            vdirsyncer-davmail = {
              Unit = {
                After = [ "davmail.service" ];
                Description = "Work calendar synchronization";
                OnFailure = [ "vdirsyncer-davmail-notify.service" ];
                Requires = [ "davmail.service" ];
                "X-SwitchMethod" = "keep-old";
              };

              Service = {
                Type = "oneshot";
                ExecStartPre = [ davmailReady ];
                ExecStart = [ davmailSync ];
                ExecStartPost = [
                  "${lib.getExe' pkgs.coreutils "touch"} ${lib.escapeShellArg davmailLastSuccess}"
                  "${lib.getExe' pkgs.coreutils "rm"} -f ${lib.escapeShellArg davmailFailureStamp}"
                ];
                TimeoutStartSec = "3m";
                UMask = "0077";
              };
            };

            vdirsyncer-davmail-notify = {
              Unit = {
                ConditionPathExists = "!${davmailFailureStamp}";
                Description = "Notify about paused work calendar synchronization";
              };
              Service = {
                Type = "oneshot";
                ExecStart = [ davmailFailureNotify ];
              };
            };
          };

          timers.vdirsyncer-davmail = {
            Unit.Description = "Work calendar synchronization";
            Timer = {
              OnCalendar = "*:5/15";
              Persistent = true;
              Unit = "vdirsyncer-davmail.service";
            };
            Install.WantedBy = [ "timers.target" ];
          };
        };

        home.packages = [ workCalendarAuth ];
      })
    ]
  );
}
