{
  core = {
    description = "Core Nix ecosystem";
    inputs = [
      "nixpkgs"
      "nixpkgs-unstable"
      "nixpkgs-master"
      "flake-compat"
      "flake-parts"
      "systems"
    ];
  };

  system = {
    description = "System management";
    inputs = [
      "disko"
      "fast-nix-gc"
      "home-manager"
      "jovian"
      "lanzaboote"
      "nix-darwin"
      "nix-rosetta-builder"
      "nixos-wsl"
      "sops-nix"
    ];
  };

  apps = {
    description = "Applications & packages";
    inputs = [
      "adv360-zmk"
      "anyrun-nixos-options"
      "catppuccin"
      "claude-plugins-official"
      "codex-desktop-linux"
      "firefox-addons"
      "hermes-agent"
      "khanelivim"
      "llm-agents"
      "mcp-servers-nix"
      "nix-flatpak"
      "nix-index-database"
      "plasma-manager"
      "stylix"
      "t3code"
      "tokyonight"
      "waybar"
      "yazi-flavors"
      "zmk-nix"
    ];
  };
}
