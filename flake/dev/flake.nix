{
  description = "Private inputs for development purposes. These are used by the top level flake in the `dev` partition, but do not appear in consumers' lock files.";

  inputs = {
    # By pointing to the parent directory, this flake can "follow" the inputs
    # of the root flake, ensuring dependency versions are kept in sync.
    root = {
      url = "path:./../..";
      # Unneeded in dev flake
      inputs = {
        khanelivim.follows = "";
        disko.follows = "";
        lanzaboote.follows = "";
        nix-darwin.follows = "";
        nix-rosetta-builder.follows = "";
        nixos-wsl.follows = "";
        anyrun-nixos-options.follows = "";
        catppuccin.follows = "";
        firefox-addons.follows = "";
        hypr-socket-watch.follows = "";
        nh.follows = "";
        niri.follows = "";
        nix-flatpak.follows = "";
        nix-index-database.follows = "";
        stylix.follows = "";
        waybar.follows = "";
        yazi-flavors.follows = "";
      };
    };

    nixpkgs.follows = "root/nixpkgs";
    nixpkgs-master.follows = "root/nixpkgs-master";
    nixpkgs-unstable.follows = "root/nixpkgs-unstable";
    flake-compat.follows = "root/flake-compat";

    # keep-sorted start block=yes newline_separated=yes
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "root/nixpkgs";
    };

    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "root/nixpkgs";
      inputs.flake-compat.follows = "flake-compat";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "root/nixpkgs";
    };
    # keep-sorted end
  };

  # This flake is only used for its inputs.
  outputs = _inputs: { };
}
