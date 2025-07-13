{ channels, ... }:
_final: _prev: {
  inherit (channels.nixpkgs-master)
    # Fast updating / want latest always
    claude-code
    yaziPlugins

    # TODO: remove after channel update
    # Somehow randomly broke on missing package error ??
    citrix_workspace
    ;
}
