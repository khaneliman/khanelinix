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
      enable = true;
      servers = {
        filesystem = {
          command = getExe mcpPkgs.mcp-server-filesystem;
          args = lib.mkDefault [
            config.home.homeDirectory
            "${config.home.homeDirectory}/Documents"
          ];
        };

        # FIXME: broken darwin
        github = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
          command = getExe pkgs.github-mcp-server;
          args = [
            "--read-only"
            "stdio"
          ];
        };

        # FIXME: broken darwin
        nixos = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
          command = getExe pkgs.mcp-nixos;
        };
      };
    };
  };
}
