{
  config,
  lib,
  pkgs,

  ...
}:
let
  cfg = config.khanelinix.system.tcc;
  userName = config.khanelinix.user.name;
  stableBinaries =
    if userName == null then
      { }
    else
      config.home-manager.users.${userName}.khanelinix.system.tcc.stableBinaries or { };
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

  config = lib.mkMerge [
    (lib.mkIf (stableBinaries != { }) {
      # extraActivation runs before nix-darwin and Home Manager reload launch
      # agents, so restarted daemons start from the new copies.
      system.activationScripts.extraActivation.text = ''
        echo >&2 "Installing stable TCC binaries..."

        installStableBinary() {
          local source="$1" target="$2"
          local staged

          if [[ -e "$target" ]] && cmp -s "$source" "$target"; then
            return
          fi

          [[ -d "''${target%/*}" ]] || /usr/bin/sudo -u ${lib.escapeShellArg userName} /bin/mkdir -p "''${target%/*}"
          staged="$(mktemp "''${target%/*}/.tcc-stable.XXXXXX")"
          cp "$source" "$staged"
          chmod 555 "$staged"
          # Rename instead of overwriting so a running daemon keeps its mapped image.
          mv -f "$staged" "$target"
        }

        ${lib.concatMapAttrsStringSep "\n" (
          _: binary:
          "installStableBinary ${lib.escapeShellArg binary.source} ${lib.escapeShellArg binary.path}"
        ) stableBinaries}
      '';
    })

    (lib.mkIf (cfg.pruneStaleAccessibilityPermissions && userName != null) {
      system.activationScripts.extraActivation.text = lib.mkAfter ''
        echo >&2 "Auditing Accessibility TCC entries..."

        tccDb="/Library/Application Support/com.apple.TCC/TCC.db"
        if [ ! -f "$tccDb" ]; then
          echo >&2 "Skipping Accessibility TCC audit: system TCC database is missing."
        else
          export KHANELINIX_TCC_STABLE_CLIENTS=${
            lib.escapeShellArg (builtins.toJSON (lib.mapAttrsToList (_: binary: binary.path) stableBinaries))
          }
          "${lib.getExe pkgs.python3}" "${accessibilityCleanup}" >&2
        fi
      '';
    })
  ];
}
