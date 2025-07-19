{ inputs, ... }:
{
  flake.lib = {
    # keep-sorted start block=yes newline_separated=yes
    base64 = import ./base64 { inherit inputs; };
    file = import ./file {
      inherit inputs;
      self = ../.;
    };
    module = import ./module { inherit inputs; };
    overlay = import ./overlay.nix { inherit inputs; };
    system = import ./system { inherit inputs; };
    theme = import ./theme { inherit inputs; };
    # keep-sorted end
  };
}
