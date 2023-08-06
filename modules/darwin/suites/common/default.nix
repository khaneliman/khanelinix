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
  imports = [ ../../../shared/suites/common/default.nix ];

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
      duti
      fasd
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
      lolcat
      lsd
      mas
      moreutils
      ncdu
      oh-my-posh
      pciutils
      pigz
      rename
      spice-gtk
      terminal-notifier
      tmux
      toilet
      topgrade
      trash-cli
      tree
      wego
      wtf
    ];

    khanelinix = {
      nix = enabled;

      apps = { };

      cli-apps = {
        ranger = enabled;
      };

      tools = {
        git = enabled;
        homebrew = enabled;
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
