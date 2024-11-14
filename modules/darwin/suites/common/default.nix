{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) enabled;

  cfg = config.${namespace}.suites.common;
in
{
  imports = [ (lib.snowfall.fs.get-file "modules/shared/suites/common/default.nix") ];

  config = mkIf cfg.enable {
    programs.zsh.enable = true;

    homebrew = {
      brews = [
        "bashdb"
        "gnu-sed"
      ];
    };

    environment = {
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
        pkgs.${namespace}.trace-symlink
        pkgs.${namespace}.trace-which
        mas
        moreutils
        oh-my-posh
        pigz
        rename
        spice-gtk
        terminal-notifier
        trash-cli
        wtf
      ];
    };

    khanelinix = {
      home.extraOptions = {
        home.shellAliases = {
          # Prevent shell log command from overriding macos log
          log = ''command log'';
        };
      };

      nix = enabled;

      tools = {
        homebrew = enabled;
      };

      system = {
        fonts = enabled;
        input = enabled;
        interface = enabled;
        networking = enabled;
      };
    };
  };
}
