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
    hasAttrByPath
    ;

  cfg = config.khanelinix.programs.terminal.tools.mcp;
  mcpPkgs = inputs.mcp-servers-nix.packages.${system};
  hasTavilyApiKey = hasAttrByPath [ "sops" "secrets" "TAVILY_API_KEY" ] config;
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
            "/nix/store"
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
        }
        // lib.optionalAttrs hasTavilyApiKey {
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
