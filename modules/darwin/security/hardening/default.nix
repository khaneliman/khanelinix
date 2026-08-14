{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    types
    ;

  cfg = config.khanelinix.security.hardening;
  expectedStateType = types.enum [
    "enabled"
    "disabled"
    "ignore"
  ];
in
{
  options.khanelinix.security.hardening = {
    enable = mkEnableOption "declarative macOS security hardening";

    updates = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to configure automatic macOS security and operating system updates.";
      };

      automaticCheck = mkOption {
        type = types.bool;
        default = true;
        description = "Whether macOS checks for updates automatically.";
      };

      automaticDownload = mkOption {
        type = types.bool;
        default = true;
        description = "Whether macOS downloads available updates automatically.";
      };

      configurationDataInstall = mkOption {
        type = types.bool;
        default = true;
        description = "Whether macOS installs system data files automatically.";
      };

      criticalUpdateInstall = mkOption {
        type = types.bool;
        default = true;
        description = "Whether macOS installs critical updates automatically.";
      };

      scheduleFrequency = mkOption {
        type = types.ints.positive;
        default = 1;
        description = "Number of days between scheduled update checks.";
      };

      operatingSystemInstall = mkOption {
        type = types.bool;
        default = true;
        description = "Whether macOS installs operating system updates automatically.";
      };
    };

    loginWindow = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to configure hardened login window settings.";
      };

      disableConsoleAccess = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to disable the login window console prompt.";
      };

      showFullName = mkOption {
        type = types.bool;
        default = false;
        description = "Whether the login window shows name and password fields instead of users.";
      };
    };

    screenLock = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to configure password requirements after the screen saver starts.";
      };

      requirePassword = mkOption {
        type = types.bool;
        default = true;
        description = "Whether macOS requires a password after the screen saver starts.";
      };

      delay = mkOption {
        type = types.ints.unsigned;
        default = 0;
        description = "Delay in seconds before macOS requires the password.";
      };
    };

    audit = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether activation audits security controls that nix-darwin cannot safely change.";
      };

      expected = {
        fileVault = mkOption {
          type = expectedStateType;
          default = "enabled";
          description = "Expected FileVault state.";
        };

        systemIntegrityProtection = mkOption {
          type = expectedStateType;
          default = "enabled";
          description = "Expected System Integrity Protection state.";
        };

        authenticatedRoot = mkOption {
          type = expectedStateType;
          default = "enabled";
          description = "Expected authenticated root state.";
        };

        gatekeeper = mkOption {
          type = expectedStateType;
          default = "enabled";
          description = "Expected Gatekeeper assessment state.";
        };

        arm64ePreviewAbi = mkOption {
          type = types.enum [
            "present"
            "absent"
            "ignore"
          ];
          default = "absent";
          description = "Expected presence of -arm64e_preview_abi in the NVRAM boot arguments.";
        };
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf cfg.updates.enable {
      system.defaults = {
        CustomSystemPreferences."/Library/Preferences/com.apple.SoftwareUpdate" = {
          AutomaticCheckEnabled = lib.mkDefault cfg.updates.automaticCheck;
          AutomaticDownload = lib.mkDefault cfg.updates.automaticDownload;
          ConfigDataInstall = lib.mkDefault cfg.updates.configurationDataInstall;
          CriticalUpdateInstall = lib.mkDefault cfg.updates.criticalUpdateInstall;
          ScheduleFrequency = lib.mkDefault cfg.updates.scheduleFrequency;
        };

        SoftwareUpdate.AutomaticallyInstallMacOSUpdates = lib.mkDefault cfg.updates.operatingSystemInstall;
      };
    })

    (mkIf cfg.loginWindow.enable {
      system.defaults.loginwindow = {
        DisableConsoleAccess = lib.mkDefault cfg.loginWindow.disableConsoleAccess;
        SHOWFULLNAME = lib.mkDefault cfg.loginWindow.showFullName;
      };
    })

    (mkIf cfg.screenLock.enable {
      system.defaults.screensaver = {
        askForPassword = lib.mkDefault cfg.screenLock.requirePassword;
        askForPasswordDelay = lib.mkDefault cfg.screenLock.delay;
      };
    })

    (mkIf cfg.audit.enable {
      system.activationScripts.postActivation.text = lib.mkAfter /* Bash */ ''
        echo >&2 "Auditing macOS controls that nix-darwin cannot enable safely..."

        reportSecurityMismatch() {
          control="$1"
          expected="$2"
          actual="$3"

          if [ "$actual" != "$expected" ]; then
            echo >&2 "Warning: $control is $actual; expected $expected."
          fi
        }

        reportSecurityProbeFailure() {
          control="$1"
          detail="$2"
          echo >&2 "Warning: Could not determine $control state: $detail"
        }

        ${lib.optionalString (cfg.audit.expected.fileVault != "ignore") ''
          if [ ! -x /usr/bin/fdesetup ]; then
            reportSecurityProbeFailure "FileVault" "fdesetup is unavailable."
          else
            if fileVaultOutput="$(LC_ALL=C /usr/bin/fdesetup isactive 2>&1)"; then
              fileVaultProbeStatus=0
            else
              fileVaultProbeStatus=$?
            fi

            case "$fileVaultOutput" in
              true) fileVaultState="enabled" ;;
              false) fileVaultState="disabled" ;;
              *)
                fileVaultState=""
                if [ "$fileVaultProbeStatus" -eq 0 ]; then
                  reportSecurityProbeFailure "FileVault" "unrecognized fdesetup output: $fileVaultOutput"
                else
                  reportSecurityProbeFailure "FileVault" "fdesetup isactive failed: $fileVaultOutput"
                fi
                ;;
            esac

            if [ -n "$fileVaultState" ]; then
              reportSecurityMismatch "FileVault" ${lib.escapeShellArg cfg.audit.expected.fileVault} "$fileVaultState"
            fi
          fi
        ''}

        ${lib.optionalString (cfg.audit.expected.systemIntegrityProtection != "ignore") ''
          if [ ! -x /usr/bin/csrutil ]; then
            reportSecurityProbeFailure "System Integrity Protection" "csrutil is unavailable."
          else
            if sipOutput="$(LC_ALL=C /usr/bin/csrutil status 2>&1)"; then
              sipProbeStatus=0
            else
              sipProbeStatus=$?
            fi

            case "$sipOutput" in
              *"status: enabled"*) sipState="enabled" ;;
              *"status: disabled"*) sipState="disabled" ;;
              *)
                sipState=""
                if [ "$sipProbeStatus" -eq 0 ]; then
                  reportSecurityProbeFailure "System Integrity Protection" "unrecognized csrutil output: $sipOutput"
                else
                  reportSecurityProbeFailure "System Integrity Protection" "csrutil status failed: $sipOutput"
                fi
                ;;
            esac

            if [ -n "$sipState" ]; then
              reportSecurityMismatch "System Integrity Protection" ${lib.escapeShellArg cfg.audit.expected.systemIntegrityProtection} "$sipState"
            fi
          fi
        ''}

        ${lib.optionalString (cfg.audit.expected.authenticatedRoot != "ignore") ''
          if [ ! -x /usr/bin/csrutil ]; then
            reportSecurityProbeFailure "authenticated root" "csrutil is unavailable."
          else
            if authenticatedRootOutput="$(LC_ALL=C /usr/bin/csrutil authenticated-root status 2>&1)"; then
              authenticatedRootProbeStatus=0
            else
              authenticatedRootProbeStatus=$?
            fi

            case "$authenticatedRootOutput" in
              *"status: enabled"*) authenticatedRootState="enabled" ;;
              *"status: disabled"*) authenticatedRootState="disabled" ;;
              *)
                authenticatedRootState=""
                if [ "$authenticatedRootProbeStatus" -eq 0 ]; then
                  reportSecurityProbeFailure "authenticated root" "unrecognized csrutil output: $authenticatedRootOutput"
                else
                  reportSecurityProbeFailure "authenticated root" "csrutil authenticated-root status failed: $authenticatedRootOutput"
                fi
                ;;
            esac

            if [ -n "$authenticatedRootState" ]; then
              reportSecurityMismatch "authenticated root" ${lib.escapeShellArg cfg.audit.expected.authenticatedRoot} "$authenticatedRootState"
            fi
          fi
        ''}

        ${lib.optionalString (cfg.audit.expected.gatekeeper != "ignore") ''
          if [ ! -x /usr/sbin/spctl ]; then
            reportSecurityProbeFailure "Gatekeeper" "spctl is unavailable."
          else
            if gatekeeperOutput="$(LC_ALL=C /usr/sbin/spctl --status 2>&1)"; then
              gatekeeperProbeStatus=0
            else
              gatekeeperProbeStatus=$?
            fi

            case "$gatekeeperOutput" in
              *"assessments enabled"*) gatekeeperState="enabled" ;;
              *"assessments disabled"*) gatekeeperState="disabled" ;;
              *)
                gatekeeperState=""
                if [ "$gatekeeperProbeStatus" -eq 0 ]; then
                  reportSecurityProbeFailure "Gatekeeper" "unrecognized spctl output: $gatekeeperOutput"
                else
                  reportSecurityProbeFailure "Gatekeeper" "spctl --status failed: $gatekeeperOutput"
                fi
                ;;
            esac

            if [ -n "$gatekeeperState" ]; then
              reportSecurityMismatch "Gatekeeper" ${lib.escapeShellArg cfg.audit.expected.gatekeeper} "$gatekeeperState"
            fi
          fi
        ''}

        ${lib.optionalString (cfg.audit.expected.arm64ePreviewAbi != "ignore") ''
          if [ ! -x /usr/sbin/nvram ]; then
            reportSecurityProbeFailure "arm64e preview ABI boot argument" "nvram is unavailable."
          elif nvramOutput="$(LC_ALL=C /usr/sbin/nvram -p 2>&1)"; then
            bootArgs="$(/usr/bin/printf '%s\n' "$nvramOutput" | /usr/bin/awk '$1 == "boot-args" { $1 = ""; sub(/^[[:space:]]+/, ""); print }')"

            case " $bootArgs " in
              *" -arm64e_preview_abi "*) arm64ePreviewAbiState="present" ;;
              *) arm64ePreviewAbiState="absent" ;;
            esac

            reportSecurityMismatch "arm64e preview ABI boot argument" ${lib.escapeShellArg cfg.audit.expected.arm64ePreviewAbi} "$arm64ePreviewAbiState"
          else
            reportSecurityProbeFailure "arm64e preview ABI boot argument" "nvram -p failed: $nvramOutput"
          fi
        ''}
      '';
    })
  ]);
}
