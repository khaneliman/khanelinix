{
  config,
  lib,
  # pkgs,
  inputs,
  system,
  ...
}:
let
  inherit (lib)
    getExe
    ;

  cfg = config.khanelinix.programs.terminal.tools.mcp;
  mcpPkgs = inputs.mcp-servers-nix.packages.${system};
in
{
  options.khanelinix.programs.terminal.tools.mcp = {
    enable = lib.mkEnableOption "MCP (Model Context Protocol) servers";
  };

  config = lib.mkIf cfg.enable {
    programs.mcp = {
      # MCP documentation
      # See: https://modelcontextprotocol.io/
      enable = true;
      servers = {
        fetch = {
          command = getExe mcpPkgs.mcp-server-fetch;
        };

        filesystem = {
          command = getExe mcpPkgs.mcp-server-filesystem;
          args = lib.mkDefault [
            config.home.homeDirectory
            "${config.home.homeDirectory}/Documents"
            "${config.home.homeDirectory}/khanelinix"
          ];
        };

        sequential-thinking = {
          command = getExe mcpPkgs.mcp-server-sequential-thinking;
        };

        git = {
          command = getExe mcpPkgs.mcp-server-git;
        };

        tavily = {
          command = getExe mcpPkgs.tavily-mcp;
          env = {
            # Handled by development suite via shell exports, but good to be explicit
            TAVILY_API_KEY = "$(cat ${config.sops.secrets.TAVILY_API_KEY.path})";
          };
        };

        # FIXME: broken nixpkgs
        # nixos = {
        #   command = getExe pkgs.mcp-nixos;
        # };
      };
    };
  };
}
