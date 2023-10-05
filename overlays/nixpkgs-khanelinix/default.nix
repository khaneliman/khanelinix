{ channels, ... }: _final: prev: {
  inherit (channels.nixpkgs-khanelinix) _1password-gui-beta;
}
