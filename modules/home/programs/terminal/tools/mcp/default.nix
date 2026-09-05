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
  blenderMcpPackage = pkgs.khanelinix.blender-mcp;
in
{
  options.khanelinix.programs.terminal.tools.mcp = {
    enable = lib.mkEnableOption "MCP (Model Context Protocol) servers";

    blender = {
      enable = lib.mkEnableOption "Blender MCP server and add-on";
      host = lib.mkOption {
        type = lib.types.str;
        default = "localhost";
        description = "Host where the Blender MCP add-on listens.";
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 9876;
        description = "Port where the Blender MCP add-on listens.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.optionals cfg.blender.enable [ pkgs.blender ];

    home.activation.blenderMcpExtension = lib.mkIf cfg.blender.enable (
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${getExe pkgs.blender} \
          --online-mode \
          --background \
          --factory-startup \
          --command extension install-file \
          "${blenderMcpPackage}/share/blender-mcp/addon/blender_mcp_addon-1.0.0.zip" \
          --repo user_default \
          --enable
      ''
    );

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

        blender = {
          enabled = cfg.blender.enable;
          command = getExe blenderMcpPackage;
          env = {
            BLENDER_MCP_HOST = cfg.blender.host;
            BLENDER_MCP_PORT = toString cfg.blender.port;
          };
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

        # BLOCKED: no packaged Azure DevOps MCP server. Neither
        # mcp-servers-nix nor the pinned nixpkgs ships @azure-devops/mcp, and
        # every server here runs a store path instead of a fetched command.
        # Add the entry once the server is packaged, and read the PAT from
        # sops the same way tavily reads TAVILY_API_KEY.

        nixos = {
          # Native nix eval and the pinned source trees cover routine lookups.
          enabled = false;
          command = getExe pkgs.mcp-nixos;
        };
      };
    };
  };
}
