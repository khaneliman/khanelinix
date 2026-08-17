{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.khanelinix.programs.graphical.apps.antigravity;
  aiTools = import (lib.getFile "modules/common/ai-tools") { inherit lib pkgs; };
in
{
  options.khanelinix.programs.graphical.apps.antigravity = {
    enable = lib.mkEnableOption "Antigravity standalone configuration";
  };

  config = lib.mkIf cfg.enable {
    home.file = lib.mapAttrs' (
      name: source:
      lib.nameValuePair ".gemini/config/skills/${name}" {
        source = lib.mkDefault source;
        recursive = true;
      }
    ) aiTools.antigravityCli.skills;
  };
}
