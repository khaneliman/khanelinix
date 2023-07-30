{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.suites.development;
in
{
  options.khanelinix.suites.development = with types; {
    enable =
      mkBoolOpt false
        "Whether or not to enable common development configuration.";
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [
      12345
      3000
      3001
      8080
      8081
    ];

    environment.systemPackages = with pkgs; [
      onefetch
      clang
      cmake
      dotnet-sdk_7
      dotnet-runtime_7
      gcc
      glib
      glibc
      libgccjit
      stdenvNoCC
      libcxx
      libcxxStdenv
      gnumake
      llvm
      meson
      pkg-config
      rust-bin.stable.latest.default

      #nix
      nixpkgs-fmt
      nixpkgs-review
      nixpkgs-lint-community
      nixpkgs-hammering
    ];

    khanelinix = {
      apps = {
        neovide = enabled;
        vscode = enabled;
        yubikey = enabled;
      };

      cli-apps = {
        helix = enabled;
        lazydocker = enabled;
        lazygit = enabled;
        neovim = enabled;
        prisma = enabled;
        tmux = enabled;
        yubikey = enabled;
      };

      tools = {
        git-crypt = enabled;
        go = enabled;
        k8s = enabled;
        node = enabled;
        python = enabled;
        tree-sitter = enabled;
      };

      virtualisation = { podman = enabled; };
    };
  };
}
