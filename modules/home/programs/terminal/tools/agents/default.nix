{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mapAttrs'
    nameValuePair
    ;
  cfg = config.khanelinix.programs.terminal.tools.agents;
  aiTools = import (lib.getFile "modules/common/ai-tools") { inherit lib; };
  inherit (aiTools) agentsConfig;

  yamlFormat = pkgs.formats.yaml { };
in
{
  options.khanelinix.programs.terminal.tools.agents = {
    enable = mkEnableOption ".agents directory configuration";
  };

  config = mkIf cfg.enable {
    home.file = {
      ".agents/manifest.yaml".source = yamlFormat.generate "manifest.yaml" agentsConfig.manifest;
      ".agents/prompts/base.md".text = agentsConfig.prompts.base;

      # Ensure directory structure exists
      ".agents/policies/.keep".text = "";
      ".agents/scopes/.keep".text = "";
      ".agents/profiles/.keep".text = "";
      ".agents/schemas/.keep".text = "";
      ".agents/state/.keep".text = "";
      ".agents/state/.gitignore".text = "state.yaml\n";
    }
    // (mapAttrs' (
      name: content: nameValuePair ".agents/modes/${name}.md" { text = content; }
    ) agentsConfig.modes)
    // (mapAttrs' (
      name: content: nameValuePair ".agents/prompts/snippets/${name}.md" { text = content; }
    ) agentsConfig.prompts.snippets)
    // (mapAttrs' (
      name: path: nameValuePair ".agents/skills/${name}" { source = path; }
    ) aiTools.skills);
  };
}
