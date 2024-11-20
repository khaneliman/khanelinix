{
  config,
  lib,
  pkgs,
  root,
  ...
}:
let
  inherit (lib) mkIf mkDefault;
  inherit (lib.khanelinix) enabled;

  cfg = config.khanelinix.suites.common;
in
{
  imports = [ (root + "/modules/shared/suites/common/default.nix") ];

  config = mkIf cfg.enable {
    programs.zsh.enable = mkDefault true;

    homebrew = {
      brews = [
        "bashdb"
      ];
    };

    environment = {
      systemPackages = with pkgs; [
        duti
        gawk
        gnugrep
        gnupg
        gnused
        gnutls
        pkgs.khanelinix.trace-symlink
        pkgs.khanelinix.trace-which
        mas
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

      nix = mkDefault enabled;

      programs.terminal.tools.ssh = mkDefault enabled;

      tools = {
        homebrew = mkDefault enabled;
      };

      services = {
        openssh = mkDefault enabled;
      };

      system = {
        fonts = mkDefault enabled;
        input = mkDefault enabled;
        interface = mkDefault enabled;
        networking = mkDefault enabled;
      };
    };
  };
}
