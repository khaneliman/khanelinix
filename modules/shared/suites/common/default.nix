{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.suites.common;
in
{
  options.khanelinix.suites.common = with types; {
    enable = mkBoolOpt false "Whether or not to enable common configuration.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      coreutils
      curl
      exa
      fd
      file
      findutils
      khanelinix.list-iommu
      killall
      pciutils
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
