{
  config,
  lib,
  pkgs,

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
    environment.systemPackages =
      with pkgs;
      [
        cutter
      ]
      ++ lib.optionals cfg.dockerEnable [
        podman-desktop
      ];

    khanelinix.nix.nix-rosetta-builder.enable = true;

    homebrew = {
      casks =
        lib.optionals cfg.dockerEnable [
          "docker-desktop"
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
