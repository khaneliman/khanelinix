{
  config,
  lib,
  pkgs,

  ...
}:
let
  cfg = config.khanelinix.services.time-machine;
  exclusions = pkgs.writeText "time-machine-exclusions" (
    lib.concatStringsSep "\n" cfg.exclusions + "\n"
  );
  stateDirectory = "/var/db/khanelinix";
  stateFile = "${stateDirectory}/time-machine-exclusions";
in
{
  options.khanelinix.services.time-machine = {
    enable = lib.mkEnableOption "Time Machine policy";
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
    ];

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

      ${lib.optionalString (cfg.expectedDestination != null) ''
        if ! /usr/bin/tmutil destinationinfo 2>/dev/null \
          | /usr/bin/grep -Fq -- ${lib.escapeShellArg cfg.expectedDestination}; then
          echo >&2 ${lib.escapeShellArg "Warning: Expected Time Machine destination is not configured: ${cfg.expectedDestination}"}
        fi
      ''}
    '';
  };
}
