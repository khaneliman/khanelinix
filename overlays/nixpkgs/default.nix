{ channels, ... }:
_final: _prev: {
  # TODO: remove after fixed in unstable
  inherit (channels.nixpkgs-small) swayfx swaylock-effects;
}
