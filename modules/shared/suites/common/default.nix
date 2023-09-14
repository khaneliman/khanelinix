{ options
, config
, lib
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;
  cfg = config.khanelinix.suites.common;
in
{
  options.khanelinix.suites.common = {
    enable = mkBoolOpt false "Whether or not to enable common configuration.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      coreutils
      curl
      eza
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
  };
}
