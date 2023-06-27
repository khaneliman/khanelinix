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
    environment.systemPackages = with pkgs; [
      appimage-run
      bottom
      clac
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
      snowfallorg.flake
      statix
    ];

    khanelinix = {
      nix = enabled;

      cli-apps = {
        btop = enabled;
        fastfetch = enabled;
        ranger = enabled;
      };

      tools = {
        bat = enabled;
        comma = enabled;
        colorls = enabled;
        direnv = enabled;
        fup-repl = enabled;
        git = enabled;
        glxinfo = enabled;
        lsd = enabled;
        nix-ld = enabled;
        oh-my-posh = enabled;
        spicetify-cli = enabled;
        topgrade = enabled;
      };

      hardware = {
        audio = enabled;
        networking = enabled;
        storage = enabled;
      };

      services = {
        printing = enabled;
        openssh = enabled;
        tailscale = enabled;
      };

      security = {
        doas = enabled;
        gpg = enabled;
        keyring = enabled;
        polkit = enabled;
      };

      system = {
        boot = enabled;
        fonts = enabled;
        locale = enabled;
        time = enabled;
        xkb = enabled;
      };
    };
  };
}
