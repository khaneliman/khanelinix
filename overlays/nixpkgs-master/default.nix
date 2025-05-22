{ channels, ... }:
_final: _prev: {
  inherit (channels.nixpkgs-master)
    # TODO: remove after 1.0 hits os-unstable
    claude-code
    # TODO: remove after package hits pkgs-unstable
    sbarlua
    yaziPlugins
    ;
}
