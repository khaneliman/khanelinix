{ inputs }:
final: _prev: {
  inherit (inputs.mcp-servers-nix.packages.${final.stdenv.hostPlatform.system})
    mcp-server-filesystem
    mcp-server-sequential-thinking
    ;
}
