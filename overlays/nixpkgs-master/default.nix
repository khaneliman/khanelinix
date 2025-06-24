{ channels, ... }:
_final: _prev: {
  inherit (channels.nixpkgs-master)
    claude-code
    yaziPlugins

    # TODO: remove after hits channel
    pngpaste
    ;
}
