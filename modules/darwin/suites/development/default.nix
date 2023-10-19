{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt enabled;

  cfg = config.khanelinix.suites.development;
in
{
  options.khanelinix.suites.development = {
    enable =
      mkBoolOpt false
        "Whether or not to enable common development configuration.";
  };

  config = mkIf cfg.enable {
    khanelinix = {
      tools = {
        node = enabled;
        python = enabled;
      };
    };

    environment.systemPackages = with pkgs; [
      mysql-client
      neovide
      rustup
      jdk

      #nix
      nixpkgs-fmt
      nixpkgs-review
      nixpkgs-lint-community
      nixpkgs-hammering
      nix-update
    ];

    homebrew = {
      brews = [
        "brew-cask-completion"
        "gh"
        "angular-cli"
      ];

      casks = [
        "cutter"
        "docker"
        "electron"
        "powershell"
        "visual-studio-code"
      ];

      taps = [
        "cloudflare/cloudflare"
        "earthly/earthly"
      ];

      masApps = mkIf config.khanelinix.tools.homebrew.masEnable {
        "Patterns" = 429449079;
        "Xcode" = 497799835;
      };
    };
  };
}
