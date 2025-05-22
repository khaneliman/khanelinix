{ channels, ... }:
_final: _prev: {
  inherit (channels.nixpkgs-master)
    sbarlua
    yaziPlugins
    ;
}
