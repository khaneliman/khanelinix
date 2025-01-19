{
  description = "KhaneliNix";

  inputs = {
    # Core Inputs
    ez-configs.url = "github:ehllie/ez-configs";
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager.url = "github:nix-community/home-manager";
    # home-manager.url = "git+file:///home/khaneliman/Documents/github/home-manager";
    # home-manager.url = "git+file:///Users/khaneliman/Documents/github/home-manager";
    lanzaboote.url = "github:nix-community/lanzaboote/v0.4.1"; # Secure boot
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-master.url = "github:nixos/nixpkgs";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      # url = "github:lnl7/nix-darwin";
      # NOTE: Upstream slow to respond to PRs, using own fork.
      url = "github:khaneliman/nix-darwin/cherry-picks";
      # url = "git+file:///Users/khaneliman/github/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nixos-wsl = {
      url = "github:nix-community/nixos-wsl";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix.url = "github:Mic92/sops-nix"; # Secrets management

    # Dev Inputs
    git-hooks-nix.url = "github:cachix/git-hooks.nix";
    treefmt-nix.url = "github:numtide/treefmt-nix";

    # System Deployment
    deploy-rs.url = "github:serokell/deploy-rs";
    disko.url = "github:nix-community/disko/latest";

    # Applications
    anyrun.url = "github:anyrun-org/anyrun";
    anyrun-nixos-options.url = "github:n3oney/anyrun-nixos-options";
    catppuccin-cursors.url = "github:catppuccin/cursors";
    catppuccin.url = "github:catppuccin/nix";

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland.url = "github:hyprwm/Hyprland";
    hypr-socket-watch.url = "github:khaneliman/hypr-socket-watch";

    khanelivim = {
      url = "github:khaneliman/khanelivim";
      # url = "git+file:///Users/khaneliman/Documents/github/khanelivim";
      # url = "git+file:///home/khaneliman/Documents/github/khanelivim";
      inputs = {
        # nixpkgs.follows = "nixpkgs";
        yazi.follows = "yazi";
        git-hooks-nix.follows = "git-hooks-nix";
      };
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak/latest";
    nix-index-database.url = "github:nix-community/nix-index-database";
    waybar.url = "github:Alexays/Waybar";
    yazi.url = "github:sxyazi/yazi";

    yazi-plugins = {
      url = "github:yazi-rs/plugins";
      flake = false;
    };
  };

  outputs =
    {
      flake-parts,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];

      imports = [
        ./flake
      ];
    };
}
