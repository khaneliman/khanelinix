{
  description = "KhaneliNix";

  inputs = {
    #          ╭──────────────────────────────────────────────────────────╮
    #          │                       Core System                        │
    #          ╰──────────────────────────────────────────────────────────╯
    devshell.url = "github:numtide/devshell";
    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks-nix.url = "github:cachix/git-hooks.nix";
    home-manager.url = "github:nix-community/home-manager";
    # home-manager.url = "git+file:///home/khaneliman/Documents/github/home-manager";
    # home-manager.url = "git+file:///Users/khaneliman/Documents/github/home-manager";

    lanzaboote.url = "github:nix-community/lanzaboote/v0.4.1"; # Secure boot
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    # FIXME: remove after upstream PRs are available
    nixpkgs-master.url = "github:nixos/nixpkgs";
    nixos-unified.url = "github:srid/nixos-unified";
    pkgs-by-name-for-flake-parts.url = "github:drupol/pkgs-by-name-for-flake-parts";

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
    treefmt-nix.url = "github:numtide/treefmt-nix";

    #          ╭──────────────────────────────────────────────────────────╮
    #          │                    System Deployment                     │
    #          ╰──────────────────────────────────────────────────────────╯
    deploy-rs.url = "github:serokell/deploy-rs";
    disko.url = "github:nix-community/disko/latest";

    #          ╭──────────────────────────────────────────────────────────╮
    #          │                       Applications                       │
    #          ╰──────────────────────────────────────────────────────────╯
    anyrun.url = "github:anyrun-org/anyrun";
    anyrun-nixos-options.url = "github:n3oney/anyrun-nixos-options";

    catppuccin-cursors.url = "github:catppuccin/cursors";
    catppuccin.url = "github:catppuccin/nix";

    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
    hypr-socket-watch.url = "github:khaneliman/hypr-socket-watch";

    khanelivim.url = "github:khaneliman/khanelivim";
    # khanelivim.url = "git+file:///Users/khaneliman/Documents/github/khanelivim";
    # khanelivim.url = "git+file:///home/khaneliman/Documents/github/khanelivim";

    nix-flatpak.url = "github:gmodena/nix-flatpak/latest";
    nix-index-database.url = "github:nix-community/nix-index-database";
    nur.url = "github:nix-community/NUR";
    snowfall-flake.url = "github:snowfallorg/flake";
    waybar.url = "github:Alexays/Waybar";
    wezterm.url = "github:wez/wezterm?dir=nix";

    yazi-plugins = {
      url = "github:yazi-rs/plugins";
      flake = false;
    };
  };

  # Wired using https://nixos-unified.org/autowiring.html
  outputs =
    inputs:
    inputs.nixos-unified.lib.mkFlake {
      inherit inputs;
      root = ./.;
    };

  #     templates = {
  #       angular.description = "Angular template";
  #       c.description = "C flake template.";
  #       container.description = "Container template";
  #       cpp.description = "CPP flake template";
  #       dotnetf.description = "Dotnet FSharp template";
  #       flake-compat.description = "Flake-compat shell and default files.";
  #       go.description = "Go template";
  #       node.description = "Node template";
  #       python.description = "Python template";
  #       rust.description = "Rust template";
  #       rust-web-server.description = "Rust web server template";
  #       snowfall.description = "Snowfall-lib template";
  #     };
}
