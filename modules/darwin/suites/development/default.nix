{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.${namespace}.suites.development;
in
{
  options.${namespace}.suites.development = {
    enable = lib.mkEnableOption "common development configuration";
    dockerEnable = lib.mkEnableOption "docker development configuration";
    aiEnable = lib.mkEnableOption "ai development configuration";
  };

  config = mkIf cfg.enable {
    # FIXME: not working again
    # khanelinix.nix.nix-rosetta-builder.enable = true;

    homebrew = {
      casks =
        [
          "cutter"
          "electron"
          "powershell"
        ]
        ++ lib.optionals cfg.dockerEnable [
          "docker-desktop"
          "podman-desktop"
        ]
        ++ lib.optionals cfg.aiEnable [ "ollamac" ];

      masApps = mkIf config.${namespace}.tools.homebrew.masEnable {
        "Patterns" = 429449079;
        "Xcode" = 497799835;
      };
    };
  };
}
