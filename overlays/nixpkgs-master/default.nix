{ channels, ... }:
_final: _prev: {
  inherit (channels.nixpkgs-master)
    # Fast updating / want latest always
    claude-code
    yaziPlugins
    ;
}
