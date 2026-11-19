{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf mkDefault;
  inherit (lib.khanelinix) enabled;

  cfg = config.khanelinix.suites.common;
in
{
  imports = [
    (lib.getFile "modules/common/package-profile/default.nix")
    (lib.getFile "modules/common/suites/common/default.nix")
  ];

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
          gawk
          gnugrep
          gnupg
          gnused
          gnutls
          trash-cli
          wtfutil
        ]
        ++ lib.optionals config.khanelinix.tools.homebrew.masEnable [
          mas
        ];
    };

    khanelinix = {
      home.extraOptions = {
        home.shellAliases = {
          # Prevent shell log command from overriding macos log
          log = "command log";
        };
      };

      nix = mkDefault enabled;

      security.hardening = mkDefault enabled;

      programs.terminal.tools = {
        darwin-doctor = mkDefault enabled;
        ssh = mkDefault enabled;
      };

      tools = {
        homebrew = mkDefault enabled;
      };

      services = {
        openssh = mkDefault enabled;
        time-machine = mkDefault enabled;
      };

      system = {
        logging = mkDefault enabled;
        networking = mkDefault enabled;
        power = mkDefault enabled;
      };
    };

    system.activationScripts.postActivation.text = lib.mkMerge [
      (lib.mkIf pkgs.stdenv.hostPlatform.isAarch64 /* Bash */ ''
        if ! /usr/sbin/pkgutil --pkgs | /usr/bin/grep -q "com.apple.pkg.RosettaUpdateAuto"; then
          echo >&2 "Installing Rosetta..."
          softwareupdate --install-rosetta --agree-to-license
        fi
      '')
      ''
        echo >&2 "Disabling Spotlight indexing for the Nix store..."
        sudo touch /nix/store/.metadata_never_index
      ''
      (lib.mkIf config.khanelinix.suites.desktop.enable /* Bash */ ''
        echo >&2 "Cleaning up dead LaunchServices Nix store entries..."
        /System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -dump | \
          { /usr/bin/grep -o "/nix/store/.*\.app" || test "$?" -eq 1; } | sort | uniq | while read -r app; do
          if [ ! -e "$app" ]; then
            echo >&2 "Removing dead LaunchServices entry: $app"
            /System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -u "$app"
          fi
        done
      '')
    ];
  };
}
