{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    mkMerge
    mkOption
    getExe
    types
    ;

  cfg = config.khanelinix.programs.terminal.tools.claude-code;
  mcpCfg = cfg.mcpServers;
in
{
  options.khanelinix.programs.terminal.tools.claude-code.mcpServers = {
    filesystem = {
      directories = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Directories the filesystem MCP server can access";
      };
    };
  };

  config = mkIf cfg.enable {
    programs.claude-code.mcpServers = mkMerge [
      {
        filesystem = {
          type = "stdio";
          command = getExe pkgs.mcp-server-filesystem;
          args = [ config.home.homeDirectory ] ++ mcpCfg.filesystem.directories;
        };

        # GitHub MCP - read-only for safety
        github = {
          type = "stdio";
          command = getExe pkgs.github-mcp-server;
          args = [
            "--read-only"
            "stdio"
          ];
        };

        sequential-thinking = {
          type = "stdio";
          command = getExe pkgs.mcp-server-sequential-thinking;
        };
      }
    ];
  };
}
