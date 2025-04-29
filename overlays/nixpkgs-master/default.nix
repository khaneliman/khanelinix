{ channels, ... }:
_final: _prev: {
  inherit (channels.nixpkgs-master)
    yaziPlugins
    firefox-devedition
    ;
}
