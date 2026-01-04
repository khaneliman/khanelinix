{
  config,
  lib,
  pkgs,
  inputs,
  system,
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
  # mcpPkgs = inputs.mcp-servers-nix.packages.${system};
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
          # FIXME: mcp servers fail to build
          # command = getExe mcpPkgs.mcp-server-filesystem;
          args = [ config.home.homeDirectory ] ++ mcpCfg.filesystem.directories;
        };

        # GitHub MCP - read-only for safety
        github = {
          type = "stdio";
          # FIXME: mcp servers fail to build
          # command = getExe pkgs.github-mcp-server;
          args = [
            "--read-only"
            "stdio"
          ];
        };

        memory = {
          type = "stdio";
          # FIXME: mcp servers fail to build
          # command = getExe mcpPkgs.mcp-server-memory;
        };

        nixos = {
          type = "stdio";
          # FIXME: mcp servers fail to build
          # command = getExe pkgs.mcp-nixos;
        };

        sequential-thinking = {
          type = "stdio";
          # FIXME: mcp servers fail to build
          # command = getExe mcpPkgs.mcp-server-sequential-thinking;
        };
      }
    ];
  };
}
