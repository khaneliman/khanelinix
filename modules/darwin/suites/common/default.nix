{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf mkDefault;
  inherit (lib.${namespace}) enabled;

  cfg = config.${namespace}.suites.common;
in
{
  imports = [ (lib.snowfall.fs.get-file "modules/shared/suites/common/default.nix") ];

  config = mkIf cfg.enable {
    programs.zsh.enable = mkDefault true;

    homebrew = {
      brews = [
        "bashdb"
      ];
    };

    environment = {
      systemPackages =
        with pkgs;
        [
          duti
          gawk
          gnugrep
          gnupg
          gnused
          gnutls
          pkgs.${namespace}.trace-symlink
          pkgs.${namespace}.trace-which
          pkgs.${namespace}.why-depends
          terminal-notifier
          trash-cli
          wtfutil
        ]
        ++ lib.optionals config.${namespace}.tools.homebrew.masEnable [
          mas
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

    system.activationScripts.postActivation.text = lib.mkIf pkgs.stdenv.hostPlatform.isAarch64 ''
      echo "Installing Rosetta..."
      softwareupdate --install-rosetta --agree-to-license
    '';
  };
}
