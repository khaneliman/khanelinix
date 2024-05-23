{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.suites.development;
in
{
  options.${namespace}.suites.development = {
    enable = mkBoolOpt false "Whether or not to enable common development configuration.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      mysql-client
      # FIX: nixpkg broken
      # neovide
      rustup
      jdk

      #nix
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

      masApps = mkIf config.${namespace}.tools.homebrew.masEnable {
        "Patterns" = 429449079;
        "Xcode" = 497799835;
      };
    };
  };
}
