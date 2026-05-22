{
  config,
  lib,
  pkgs,

  ...
}:
let
  cfg = config.khanelinix.system.tcc;
  accessibilityCleanup = ./accessibility-cleanup.py;
in
{
  options.khanelinix.system.tcc = {
    pruneStaleAccessibilityPermissions = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to remove stale path-based Accessibility permission entries from the system TCC database during activation.";
    };
  };

  config = lib.mkIf cfg.pruneStaleAccessibilityPermissions {
    system.activationScripts.tcc.text = lib.mkAfter ''
      echo >&2 "Auditing Accessibility TCC entries..."

      tccDb="/Library/Application Support/com.apple.TCC/TCC.db"
      if [ ! -f "$tccDb" ]; then
        echo >&2 "Skipping Accessibility TCC audit: system TCC database is missing."
      else
        tempDir="$(/usr/bin/mktemp -d /tmp/khanelinix-tcc-accessibility.XXXXXX)"

        export KHANELINIX_TCC_ACCESSIBILITY_CHANGED="$tempDir/changed"
        export KHANELINIX_TCC_ACCESSIBILITY_SUMMARY="$tempDir/summary"

        "${lib.getExe pkgs.python3}" "${accessibilityCleanup}"

        summary="$(
          /bin/cat "$KHANELINIX_TCC_ACCESSIBILITY_SUMMARY" 2>/dev/null \
            || /bin/echo "Accessibility TCC audit completed without a summary."
        )"

        echo >&2 "$summary"
        /bin/rm -rf "$tempDir"
      fi
    '';
  };
}
