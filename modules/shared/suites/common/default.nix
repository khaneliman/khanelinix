{ config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.suites.common;
in
{
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      curl
      exa
      fd
      file
      khanelinix.list-iommu
      killall
      snowfallorg.flake
      socat
      tldr
      unzip
      wget
      xclip

      # nix
      alejandra
      deadnix
      hydra-check
      nixfmt
      statix
    ];

    # khanelinix = {
    #   nix = enabled;
    #
    #   cli-apps = {
    #     btop = enabled;
    #     fastfetch = enabled;
    #     ranger = enabled;
    #   };
    #
    #   tools = {
    #     bat = enabled;
    #     comma = enabled;
    #     direnv = enabled;
    #     fup-repl = enabled;
    #     git = enabled;
    #     lsd = enabled;
    #   };
    #
    #   hardware = {
    #     networking = enabled;
    #     storage = enabled;
    #   };
    #
    #   services = {
    #     openssh = enabled;
    #   };
    #
    #   security = {
    #     doas = enabled;
    #   };
    #
    #   system = {
    #     boot = enabled;
    #     fonts = enabled;
    #     locale = enabled;
    #     time = enabled;
    #     xkb = enabled;
    #   };
    # };
  };
}
