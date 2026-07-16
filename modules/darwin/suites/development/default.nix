{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.khanelinix.suites.development;
  aiTools = import (lib.getFile "modules/common/ai-tools") { inherit lib pkgs; };
  tomlFormat = pkgs.formats.toml { };
in
{
  options.khanelinix.suites.development = {
    enable = lib.mkEnableOption "common development configuration";
    dockerEnable = lib.mkEnableOption "docker development configuration";
    aiEnable = lib.mkEnableOption "ai development configuration";
  };

  config = mkIf cfg.enable {
    homebrew = {
      casks =
        lib.optionals cfg.dockerEnable [
          "docker-desktop"
        ]
        ++ lib.optionals cfg.aiEnable [
          "codexbar"
          "ollamac"
        ];

      masApps = mkIf config.khanelinix.tools.homebrew.masEnable {
        "Patterns" = 429449079;
        "Xcode" = 497799835;
      };
    };

    nix.settings = {
      keep-derivations = true;
      keep-outputs = true;
      substituters = lib.optionals cfg.aiEnable [ "https://numtide.cachix.org" ];
      trusted-public-keys = lib.optionals cfg.aiEnable [
        "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
      ];
    };

    environment.etc = mkIf cfg.aiEnable {
      "codex/requirements.toml".source =
        tomlFormat.generate "codex-requirements" aiTools.codex.managedRequirements;
      "codex/hooks".source = aiTools.codex.hooksDir;
    };
  };
}
