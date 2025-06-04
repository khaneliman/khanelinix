{ channels, ... }:
_final: _prev: {
  inherit (channels.nixpkgs-master)
    yaziPlugins

    # TODO: remove after it makes it to channel
    bruno
    ;
}
