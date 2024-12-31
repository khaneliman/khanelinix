{ channels, ... }:
_final: _prev: {
  inherit (channels.nixpkgs-master)
    bottles
    ddccontrol
    efitools
    electron_31
    mysql-workbench
    unityhub
    ;
}
