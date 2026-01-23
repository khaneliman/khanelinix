{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.khanelinix.programs.terminal.tools.opencode;

  aiTools = import (lib.getFile "modules/common/ai-tools") { inherit lib; };
in
{
  imports = [
    ./formatters.nix
    ./lsp.nix
    ./permission.nix
    ./provider.nix
  ];

  options.khanelinix.programs.terminal.tools.opencode = {
    enable = mkEnableOption "OpenCode configuration";
  };

  config = mkIf cfg.enable {
    programs.opencode = {
      enable = true;

      enableMcpIntegration =
        let
          mcpModuleEnabled = config.khanelinix.programs.terminal.tools.mcp.enable or false;
        in
        mkIf mcpModuleEnabled true;

      settings = {
        theme = "opencode";
        model = "github-copilot/gpt-5.2";
        # TODO: enable
        # model = "github-copilot/gpt-5.2-codex";
        autoshare = false;
        autoupdate = false;

        plugin = [
          "opencode-gemini-auth@latest"
        ];

        # Disable socket.dev by default
        mcp.socket = {
          type = "remote";
          url = "https://mcp.socket.dev/";
          enabled = false;
        };
      };

      inherit (aiTools.opencode) commands;
      agents = aiTools.opencode.renderAgents;
      skills = lib.getFile "modules/common/ai-tools/skills";

      rules = builtins.readFile (lib.getFile "modules/common/ai-tools/base.md");
    };
  };
}
