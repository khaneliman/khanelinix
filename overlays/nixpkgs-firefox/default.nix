{ channels, ... }:
_final: _prev: {
  inherit (channels.nixpkgs-firefox)
    # TODO: remove when it makes it to nixos-unstable
    firefox-devedition
    ;
}
