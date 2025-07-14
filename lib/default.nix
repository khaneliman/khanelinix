{ inputs, ... }:
{
  # Extended library functions
  flake.lib = {
    # Utility functions for the flake
    mkSystem = import ./mk-system.nix { inherit inputs; };
    mkHome = import ./mk-home.nix { inherit inputs; };
    mkDarwin = import ./mk-darwin.nix { inherit inputs; };

    # File utilities
    file = import ./file { inherit inputs; self = ../.; };

    # Module utilities
    module = import ./module { inherit inputs; };

    # Theme utilities
    theme = import ./theme { inherit inputs; };

    # Base64 utilities
    base64 = import ./base64 { inherit inputs; };

    # Library overlay for extending nixpkgs lib
    overlay = import ./overlay.nix { inherit inputs; };
  };
}
