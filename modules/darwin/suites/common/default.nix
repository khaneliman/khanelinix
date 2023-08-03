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
    programs.zsh = enabled;

    environment.systemPackages = with pkgs; [
      bash-completion
      bottom
      btop
      cask
      coreutils
      curl
      duti
      exa
      fasd
      fd
      file
      findutils
      fzf
      gawk
      gnugrep
      gnupg
      gnused
      gnutls
      haskellPackages.sfnt2woff
      intltool
      jq
      keychain
      khanelinix.list-iommu
      killall
      lolcat
      lsd
      mas
      moreutils
      ncdu
      oh-my-posh
      pciutils
      pigz
      rename
      socat
      spice-gtk
      terminal-notifier
      tldr
      tmux
      toilet
      topgrade
      trash-cli
      tree
      wego
      wget
      wtf
      xclip

      # nixos
      # alejandra
      deadnix
      hydra-check
      # nixfmt
      snowfallorg.flake
      statix
    ];

    khanelinix = {
      nix = enabled;

      apps = {
        homebrew = enabled;
      };

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
