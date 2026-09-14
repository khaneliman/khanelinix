{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.khanelinix.services.harmonia;

  settings = (pkgs.formats.toml { }).generate "harmonia.toml" {
    bind = "[::]:${toString cfg.port}";
  };
in
{
  # Mirrors modules/nixos/services/harmonia. The nixpkgs module is systemd
  # only, so drive the same binary from launchd with its documented CONFIG_FILE
  # and SIGN_KEY_PATHS environment.
  options.khanelinix.services.harmonia = {
    enable = lib.mkEnableOption "Harmonia binary cache service";

    port = lib.mkOption {
      type = lib.types.port;
      default = 5000;
      description = "Port to bind Harmonia binary cache to.";
    };

    signKeyPath = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to the secret key used for signing binary cache store paths.";
    };
  };

  config = lib.mkIf cfg.enable {
    launchd.daemons.harmonia = {
      serviceConfig = {
        ProgramArguments = [ (lib.getExe pkgs.harmonia) ];
        # Runs as root: the signing key is a 0400 root sops secret and the
        # daemon needs read access to the Nix database.
        EnvironmentVariables = {
          CONFIG_FILE = "${settings}";
          # nix-store wants a writable $HOME for its temporary cache dir.
          HOME = "/var/root";
        }
        // lib.optionalAttrs (cfg.signKeyPath != null) {
          SIGN_KEY_PATHS = toString cfg.signKeyPath;
        };
        KeepAlive = true;
        RunAtLoad = true;
        StandardOutPath = "/var/log/harmonia.log";
        StandardErrorPath = "/var/log/harmonia.log";
        ProcessType = "Background";
      };
    };
  };
}
