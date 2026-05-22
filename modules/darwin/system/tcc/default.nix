{
  config,
  lib,
  pkgs,

  ...
}:
let
  cfg = config.khanelinix.system.tcc;
  userHome = config.users.users.${config.khanelinix.user.name}.home;
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
    system.activationScripts.extraActivation.text = lib.mkAfter ''
      echo >&2 "Auditing Accessibility TCC entries..."

      tccDb="/Library/Application Support/com.apple.TCC/TCC.db"
      if [ ! -f "$tccDb" ]; then
        echo >&2 "Skipping Accessibility TCC audit: system TCC database is missing."
      else
        export KHANELINIX_TCC_ACCESSIBILITY_USER_HOME="${userHome}"
        "${lib.getExe pkgs.python3}" "${accessibilityCleanup}" >&2
      fi
    '';
  };
}
