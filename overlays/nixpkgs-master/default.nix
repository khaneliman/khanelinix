{ channels, ... }:
_final: _prev: {
  inherit (channels.nixpkgs-master)
    yaziPlugins

    # TODO: remove after hits channel
    pngpaste
    ;
}
