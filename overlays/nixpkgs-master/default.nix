{ channels, ... }:
_final: _prev: {
  inherit (channels.nixpkgs-master)
    looking-glass-client
    ;
}
