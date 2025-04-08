{ channels, ... }:
_final: _prev: {
  inherit (channels.nixpkgs-yaziPlugins)
    yaziPlugins
    ;
}
