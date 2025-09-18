# OpenCode MCP (Model Context Protocol) servers configuration module
# Defines MCP servers for extending OpenCode capabilities
{ lib, pkgs, ... }:
{
  config = {
    # FIXME: seems to cause opencode to just hang
    programs.opencode.settings.mcp = {
      github = {
        type = "local";
        command = [
          (lib.getExe pkgs.github-mcp-server)
          "--read-only"
          "stdio"
        ];
        enabled = false;
      };

      socket = {
        type = "remote";
        url = "https://mcp.socket.dev/";
        enabled = false;
      };
    };
  };
}
