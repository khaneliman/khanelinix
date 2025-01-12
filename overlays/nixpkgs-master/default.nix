{ channels, ... }:
_final: _prev: {
  inherit (channels.nixpkgs-master)
    # TODO: remove after it makes it to nixpkgs-unstable
    bat-extras
    ;
}
