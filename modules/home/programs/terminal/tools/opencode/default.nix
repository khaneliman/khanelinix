{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkDefault mkIf mkEnableOption;

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
        theme = mkDefault "opencode";
        model = "github-copilot/gpt-5.2";
        # TODO: enable
        # model = "github-copilot/gpt-5.2-codex";
        autoshare = false;
        autoupdate = false;

        plugin = [
          # Support google account auth
          "opencode-gemini-auth@latest"
          # Dynamic context pruning
          "@tarquinen/opencode-dcp@latest"
          # Support background shell commands
          "opencode-pty"
          #
          "oh-my-opencode"
        ];
      };

      inherit (aiTools.opencode) commands;
      agents = aiTools.opencode.renderAgents;
      skills = lib.getFile "modules/common/ai-tools/skills";

      rules = builtins.readFile (lib.getFile "modules/common/ai-tools/base.md");
    };
  };
}
