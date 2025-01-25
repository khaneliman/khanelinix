{
  config,
  lib,
  pkgs,
  khanelinix-lib,
  self,
  ...
}:
let
  inherit (lib) mkIf mkDefault;
  inherit (khanelinix-lib) enabled;

  cfg = config.khanelinix.suites.common;
in
{
  imports = [ (khanelinix-lib.getFile "modules/shared/suites/common/default.nix") ];

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
        self.packages.${pkgs.stdenv.system}.trace-symlink
        self.packages.${pkgs.stdenv.system}.trace-which
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
