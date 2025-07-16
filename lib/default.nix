{ inputs, ... }:
{
  flake.lib = {
    mkSystem = import ./mk-system.nix { inherit inputs; };
    mkHome = import ./mk-home.nix { inherit inputs; };
    mkDarwin = import ./mk-darwin.nix { inherit inputs; };
    common = import ./common.nix { inherit inputs; };
    file = import ./file {
      inherit inputs;
      self = ../.;
    };
    module = import ./module { inherit inputs; };
    theme = import ./theme { inherit inputs; };
    base64 = import ./base64 { inherit inputs; };
    overlay = import ./overlay.nix { inherit inputs; };
  };
}
