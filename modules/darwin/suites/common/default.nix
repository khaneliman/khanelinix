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
  imports = [ ../../../shared/suites/common/default.nix ];

  config = mkIf cfg.enable {
    programs.zsh.enable = true;

    environment = {
      loginShell = pkgs.zsh;

      systemPackages = with pkgs; [
        bash-completion
        cask
        duti
        fasd
        gawk
        gnugrep
        gnupg
        gnused
        gnutls
        haskellPackages.sfnt2woff
        intltool
        keychain
        mas
        moreutils
        ncdu
        oh-my-posh
        pigz
        rename
        spice-gtk
        terminal-notifier
        trash-cli
        tree
        wego
        wtf
      ];
    };

    khanelinix = {
      nix = enabled;

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
        networking = enabled;
      };

      security = {
        # gpg = enabled;
      };
    };
  };
}
