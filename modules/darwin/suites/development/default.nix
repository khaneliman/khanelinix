{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.khanelinix.suites.development;
in
{
  options.khanelinix.suites.development = {
    enable = lib.mkEnableOption "common development configuration";
    dockerEnable = lib.mkEnableOption "docker development configuration";
    aiEnable = lib.mkEnableOption "ai development configuration";
  };

  config = mkIf cfg.enable {
    # FIXME: not working again
    # khanelinix.nix.nix-rosetta-builder.enable = true;

    homebrew = {
      casks = [
        "cutter"
      ]
      ++ lib.optionals cfg.dockerEnable [
        "docker-desktop"
        "podman-desktop"
      ]
      ++ lib.optionals cfg.aiEnable [ "ollamac" ];

      masApps = mkIf config.khanelinix.tools.homebrew.masEnable {
        "Patterns" = 429449079;
        "Xcode" = 497799835;
      };
    };

    nix.settings = {
      keep-derivations = true;
      keep-outputs = true;
    };
  };
}
