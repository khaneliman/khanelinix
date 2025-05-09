{ channels, ... }:
_final: _prev: {
  inherit (channels.nixpkgs-master)
    yaziPlugins

    # TODO: remove after nixpkgs update
    _1password-gui
    ;
}
