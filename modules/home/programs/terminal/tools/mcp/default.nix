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
          # Native browser and web tools cover routine retrieval.
          enabled = false;
          command = getExe mcpPkgs.mcp-server-fetch;
        };

        filesystem = {
          # Native file and shell tools cover repository-local reads.
          enabled = false;
          command = getExe mcpPkgs.mcp-server-filesystem;
          args = lib.mkDefault [
            config.home.homeDirectory
            "${config.home.homeDirectory}/Documents"
            "${config.home.homeDirectory}/khanelinix"
            "/nix/store"
          ];
        };

        sequential-thinking = {
          enabled = false;
          command = getExe mcpPkgs.mcp-server-sequential-thinking;
        };

        git = {
          # Native shell tools cover Git inspection and mutation.
          enabled = false;
          command = getExe mcpPkgs.mcp-server-git;
        };

        bevy-brp = {
          command = getExe pkgs.khanelinix.bevy-brp-mcp;
        };

        code-review-graph = {
          enabled = false;
          command = getExe pkgs.code-review-graph;
          args = [ "mcp" ];
        };

        semble = {
          enabled = false;
          command = lib.getExe' pkgs.semble "semble-mcp";
        };

        tavily = {
          enabled = false;
          command = getExe mcpPkgs.tavily-mcp;
        }
        // lib.optionalAttrs hasTavilyApiKey {
          env = {
            TAVILY_API_KEY.file = config.sops.secrets.TAVILY_API_KEY.path;
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
