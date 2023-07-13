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
      curl
      exa
      fd
      feh
      file
      fzf
      jq
      khanelinix.list-iommu
      killall
      pciutils
      socat
      tldr
      toilet
      unzip
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
