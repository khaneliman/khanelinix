{
  description = "Private inputs for development purposes. These are used by the top level flake in the `dev` partition, but do not appear in consumers' lock files.";

  inputs = {
    # By pointing to the parent directory, this flake can "follow" the inputs
    # of the root flake, ensuring dependency versions are kept in sync.
    root.url = "path:./../..";

    nixpkgs.follows = "root/nixpkgs";
    flake-compat.follows = "root/flake-compat";

    # keep-sorted start block=yes newline_separated=yes
    devenv = {
      url = "github:cachix/devenv";
      inputs.nixpkgs.follows = "root/nixpkgs";
    };

    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "root/nixpkgs";
      inputs.flake-compat.follows = "flake-compat";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "root/nixpkgs";
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
