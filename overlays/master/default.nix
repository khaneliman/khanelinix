{ channels, ... }:
_final: _prev: {
  inherit (channels.nixpkgs-master)
    bottles
    ddccontrol
    electron_31
    unityhub
    ;
}
