{ channels, ... }:
_final: _prev: {
  inherit (channels.nixpkgs-master)
    bottles
    bruno
    ddccontrol
    efitools
    electron_31
    mysql-workbench
    unityhub
    ;
}
