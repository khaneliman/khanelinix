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
  # TCC pins ad-hoc signed code to one exact build, so every rebuild needed a
  # new grant. A stable certificate lets grants survive rebuilds. Only root can
  # read the key, so user processes cannot sign code that inherits the grants.
  signingDirectory = "/var/db/khanelinix/tcc-signing";
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

        tccSigningDirectory=${lib.escapeShellArg signingDirectory}
        if [[ ! -s "$tccSigningDirectory/key.pem" || ! -s "$tccSigningDirectory/cert.pem" ]]; then
          echo >&2 "Creating TCC signing key..."
          # A new key invalidates every source stamp, so start from an empty directory.
          rm -rf "$tccSigningDirectory"
          /bin/mkdir -p "$tccSigningDirectory"
          /bin/chmod 700 "$tccSigningDirectory"
          (
            umask 077
            ${lib.getExe pkgs.openssl} req -x509 -newkey rsa:2048 -nodes -days 7300 \
              -subj "/CN=khanelinix-tcc" \
              -addext "basicConstraints=critical,CA:false" \
              -addext "keyUsage=critical,digitalSignature" \
              -addext "extendedKeyUsage=critical,codeSigning" \
              -keyout "$tccSigningDirectory/key.pem" \
              -out "$tccSigningDirectory/cert.pem" 2>/dev/null
          ) || echo >&2 "Warning: could not create the TCC signing key."
        fi
        tccCertificateHash="$(${lib.getExe pkgs.openssl} x509 -in "$tccSigningDirectory/cert.pem" -noout -fingerprint -sha1 2>/dev/null)"
        tccCertificateHash="''${tccCertificateHash#*=}"
        tccCertificateHash="''${tccCertificateHash//:/}"

        installStableBinary() {
          local name="$1" source="$2" target="$3"
          local stamp="$tccSigningDirectory/$name.source"
          local staged output signed=1

          # A signed copy never matches the store bytes, so compare sources instead.
          if [[ -e "$target" && "$(cat "$stamp" 2>/dev/null)" == "$source" ]]; then
            return
          fi

          [[ -d "''${target%/*}" ]] || /usr/bin/sudo -u ${lib.escapeShellArg userName} /bin/mkdir -p "''${target%/*}"
          staged="$(mktemp "''${target%/*}/.tcc-stable.XXXXXX")"
          # rcodesign falls back to an ad-hoc signature when it cannot load the
          # key, so confirm the copy carries the certificate TCC will check.
          if ! output="$(
            ${lib.getExe pkgs.rcodesign} sign \
              --pem-file "$tccSigningDirectory/key.pem" \
              --pem-file "$tccSigningDirectory/cert.pem" \
              --binary-identifier "$name" \
              "$source" "$staged" 2>&1
          )" || ! /usr/bin/codesign --verify \
            -R="identifier \"$name\" and certificate root = H\"$tccCertificateHash\"" \
            "$staged" 2>/dev/null; then
            echo >&2 "$output"
            if [[ -e "$target" ]]; then
              echo >&2 "Warning: could not sign $name for TCC; keeping $target."
              rm -f "$staged"
              return
            fi
            echo >&2 "Warning: could not sign $name for TCC; installing it unsigned."
            cp -f "$source" "$staged"
            signed=
          fi
          chmod 555 "$staged"
          # Rename instead of overwriting so a running daemon keeps its mapped image.
          mv -f "$staged" "$target"
          if [[ -n "$signed" ]]; then
            printf '%s\n' "$source" > "$stamp"
          fi

          # A process still running the old copy can fail its TCC check against
          # the new file, and an event tap that loses access blocks keyboard
          # and mouse input. Stop it so launchd relaunches the new copy.
          ps -axo pid=,comm= | while read -r pid command; do
            if [[ "$command" == "$target" ]]; then
              echo >&2 "Restarting $name to run the new copy..."
              kill "$pid" 2>/dev/null || true
            fi
          done
        }

        ${lib.concatMapAttrsStringSep "\n" (
          name: binary:
          "installStableBinary ${
            lib.escapeShellArgs [
              name
              binary.source
              binary.path
            ]
          }"
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
