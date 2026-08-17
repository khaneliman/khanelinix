{
  config,
  lib,
  pkgs,

  ...
}:
let
  cfg = config.khanelinix.services.time-machine;
  destinationUrl = "smb://${cfg.destination.user}@${cfg.destination.host}/${cfg.destination.share}";
  exclusions = pkgs.writeText "time-machine-exclusions" (
    lib.concatStringsSep "\n" cfg.exclusions + "\n"
  );
  setDestinationScript = pkgs.writeText "set-time-machine-destination.exp" (
    builtins.readFile ./set-destination.exp
  );
  stateDirectory = "/var/db/khanelinix";
  stateFile = "${stateDirectory}/time-machine-exclusions";
  credentialHashFile = "${stateDirectory}/time-machine-destination-password.sha256";
in
{
  options.khanelinix.services.time-machine = {
    enable = lib.mkEnableOption "Time Machine policy";
    destination = {
      enable = lib.mkEnableOption "authoritative SMB Time Machine destination";
      host = lib.mkOption {
        type = lib.types.str;
        default = "";
        example = "timemachine.local";
        description = "SMB server hostname without a protocol or path.";
      };
      share = lib.mkOption {
        type = lib.types.str;
        default = "TimeMachine";
        description = "SMB share name.";
      };
      user = lib.mkOption {
        type = lib.types.str;
        default = config.khanelinix.user.name;
        description = "SMB account name.";
      };
      passwordFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "/run/secrets/time-machine-password";
        description = "Runtime file containing only the SMB password.";
      };
    };
    exclusions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "/nix/store"
        "/Users/${config.khanelinix.user.name}/.cache"
        "/Users/${config.khanelinix.user.name}/Library/Developer/Xcode/DerivedData"
      ];
      description = "Fixed-path Time Machine exclusions managed by nix-darwin.";
    };
    expectedDestination = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "tm-backup.local";
      description = "Destination identifier or URL fragment to audit without storing credentials.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.all (path: lib.hasPrefix "/" path && !lib.hasInfix "\n" path) cfg.exclusions;
        message = "Time Machine exclusions must be absolute paths without newline characters.";
      }
      {
        assertion =
          !cfg.destination.enable || builtins.match "^[A-Za-z0-9.-]+$" cfg.destination.host != null;
        message = "Time Machine destination.host must be a non-empty hostname.";
      }
      {
        assertion =
          !cfg.destination.enable || builtins.match "^[A-Za-z0-9._-]+$" cfg.destination.share != null;
        message = "Time Machine destination.share contains unsupported URL characters.";
      }
      {
        assertion =
          !cfg.destination.enable || builtins.match "^[A-Za-z0-9._-]+$" cfg.destination.user != null;
        message = "Time Machine destination.user contains unsupported URL characters.";
      }
      {
        assertion =
          !cfg.destination.enable
          || (
            cfg.destination.passwordFile != null
            && lib.hasPrefix "/" cfg.destination.passwordFile
            && !lib.hasPrefix "/nix/store/" cfg.destination.passwordFile
          );
        message = "Time Machine destination.passwordFile must be an absolute runtime path outside the Nix store.";
      }
      {
        assertion = !cfg.destination.enable || cfg.expectedDestination == destinationUrl;
        message = "Time Machine expectedDestination must match the managed SMB destination URL.";
      }
    ];

    khanelinix.services.time-machine.expectedDestination = lib.mkIf cfg.destination.enable (
      lib.mkDefault destinationUrl
    );

    system.activationScripts.postActivation.text = lib.mkAfter /* Bash */ ''
      echo >&2 "Reconciling Time Machine policy..."
      /usr/bin/tmutil enable

      stateDirectory=${lib.escapeShellArg stateDirectory}
      stateFile=${lib.escapeShellArg stateFile}
      desiredFile=${exclusions}
      nextState="$stateDirectory/.time-machine-exclusions.$$"
      /bin/mkdir -p "$stateDirectory"
      : > "$nextState"
      trap '/bin/rm -f "$nextState"' EXIT

      if [ -f "$stateFile" ]; then
        while IFS= read -r previousPath; do
          [ -n "$previousPath" ] || continue
          if ! /usr/bin/grep -Fqx -- "$previousPath" "$desiredFile"; then
            /usr/bin/tmutil removeexclusion "$previousPath" 2>/dev/null || true
          fi
        done < "$stateFile"
      fi

      while IFS= read -r desiredPath; do
        [ -n "$desiredPath" ] || continue
        if [ ! -e "$desiredPath" ]; then
          echo >&2 "Warning: Time Machine exclusion path does not exist: $desiredPath"
          if [ -f "$stateFile" ] && /usr/bin/grep -Fqx -- "$desiredPath" "$stateFile"; then
            /usr/bin/printf '%s\n' "$desiredPath" >> "$nextState"
          fi
          continue
        fi

        if LC_ALL=C /usr/bin/tmutil isexcluded "$desiredPath" 2>/dev/null | /usr/bin/grep -q '^\[Excluded\]'; then
          if [ -f "$stateFile" ] && /usr/bin/grep -Fqx -- "$desiredPath" "$stateFile"; then
            /usr/bin/printf '%s\n' "$desiredPath" >> "$nextState"
          fi
          continue
        fi

        /usr/bin/tmutil addexclusion -p "$desiredPath"
        /usr/bin/printf '%s\n' "$desiredPath" >> "$nextState"
      done < "$desiredFile"

      /usr/bin/install -m 0600 "$nextState" "$stateFile"
      /bin/rm -f "$nextState"
      trap - EXIT

      ${lib.optionalString (cfg.expectedDestination != null && !cfg.destination.enable) ''
        if ! /usr/bin/tmutil destinationinfo 2>/dev/null \
          | /usr/bin/grep -Fq -- ${lib.escapeShellArg cfg.expectedDestination}; then
          echo >&2 ${lib.escapeShellArg "Warning: Expected Time Machine destination is not configured: ${cfg.expectedDestination}"}
        fi
      ''}

      ${lib.optionalString cfg.destination.enable ''
        desiredDestination=${lib.escapeShellArg destinationUrl}
        passwordFile=${lib.escapeShellArg cfg.destination.passwordFile}
        credentialHashFile=${lib.escapeShellArg credentialHashFile}

        if [ ! -r "$passwordFile" ]; then
          echo >&2 "Error: Time Machine password file is not readable: $passwordFile"
          exit 1
        fi

        destinationInfo="$(/usr/bin/tmutil destinationinfo 2>/dev/null || true)"
        destinationCount="$(
          /usr/bin/printf '%s\n' "$destinationInfo" \
            | /usr/bin/awk '/^ID[[:space:]]*:/{count++} END{print count+0}'
        )"
        desiredCredentialHash="$(
          /usr/bin/shasum -a 256 "$passwordFile" | /usr/bin/awk '{print $1}'
        )"
        currentCredentialHash=""
        if [ -r "$credentialHashFile" ]; then
          currentCredentialHash="$(/bin/cat "$credentialHashFile")"
        fi

        if [ "$destinationCount" != 1 ] \
          || ! /usr/bin/printf '%s\n' "$destinationInfo" \
            | /usr/bin/grep -Fq -- "$desiredDestination" \
          || [ "$currentCredentialHash" != "$desiredCredentialHash" ]; then
          echo >&2 "Configuring authoritative Time Machine destination: $desiredDestination"
          LC_ALL=C /usr/bin/expect ${setDestinationScript} "$desiredDestination" "$passwordFile"

          destinationInfo="$(/usr/bin/tmutil destinationinfo 2>/dev/null || true)"
          destinationCount="$(
            /usr/bin/printf '%s\n' "$destinationInfo" \
              | /usr/bin/awk '/^ID[[:space:]]*:/{count++} END{print count+0}'
          )"
          if [ "$destinationCount" != 1 ] \
            || ! /usr/bin/printf '%s\n' "$destinationInfo" \
              | /usr/bin/grep -Fq -- "$desiredDestination"; then
            echo >&2 "Error: Time Machine did not retain the declared destination."
            exit 1
          fi

          nextCredentialHash="$stateDirectory/.time-machine-destination-password.$$"
          /usr/bin/printf '%s\n' "$desiredCredentialHash" > "$nextCredentialHash"
          /usr/bin/install -m 0600 "$nextCredentialHash" "$credentialHashFile"
          /bin/rm -f "$nextCredentialHash"
        fi
      ''}
    '';
  };
}
