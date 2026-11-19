{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.khanelinix.suites.development;
  aiTools = import (lib.getFile "modules/common/ai-tools") { inherit lib pkgs; };
  tomlFormat = pkgs.formats.toml { };
in
{
  options.khanelinix.suites.development = {
    enable = lib.mkEnableOption "common development configuration";
    aiEnable = lib.mkEnableOption "ai development configuration";
  };

  config = lib.mkIf cfg.enable {
    nix.settings = {
      keep-derivations = true;
      keep-outputs = true;
    };

    environment.etc = lib.mkIf cfg.aiEnable {
      "codex/requirements.toml".source =
        tomlFormat.generate "codex-requirements" aiTools.codex.managedRequirements;
      "codex/hooks".source = aiTools.codex.hooksDir;
    };
  };
}
