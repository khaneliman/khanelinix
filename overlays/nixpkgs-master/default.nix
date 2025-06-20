{ channels, ... }:
_final: _prev: {
  inherit (channels.nixpkgs-master)
    claude-code
    yaziPlugins

    # TODO: cleanup after channel update
    citrix_workspace
    plex-desktop
    mysql-workbench
    ;
}
