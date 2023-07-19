{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.suites.common;
in {
  options.khanelinix.suites.common = with types; {
    enable = mkBoolOpt false "Whether or not to enable common configuration.";
  };

  config = mkIf cfg.enable {
    programs.zsh = enabled;

    environment.systemPackages = with pkgs; [
      bottom
      btop
      curl
      coreutils
      exa
      fasd
      fd
      file
      findutils
      fzf
      gnugrep
      gnupg
      gnused
      gnutls
      jq
      khanelinix.list-iommu
      killall
      lsd
      oh-my-posh
      pciutils
      pigz
      rename
      socat
      tldr
      tmux
      toilet
      topgrade
      trash-cli
      tree
      wget
      xclip

      # nixos
      alejandra
      deadnix
      hydra-check
      nixfmt
      # snowfallorg.flake
      statix
    ];

    khanelinix = {
      nix = enabled;

      apps = {};

      cli-apps = {
        neovim = enabled;
        ranger = enabled;
      };

      tools = {
        git = enabled;
      };

      system = {
        fonts = enabled;
        input = enabled;
        interface = enabled;
      };

      security = {
        # gpg = enabled;
      };
    };
  };
}
