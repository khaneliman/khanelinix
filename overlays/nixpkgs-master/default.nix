{ channels, ... }:
_final: _prev: {
  inherit (channels.nixpkgs-master)
    yaziPlugins

    # TODO: remove after hits channel
    dvdauthor
    handbrake
    mpd
    mysql-workbench
    plex-desktop
    pngpaste
    rocmPackages
    ;
}
