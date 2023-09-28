{ config
, lib
, options
, pkgs
, inputs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;
  inherit (inputs) spicetify-nix;

  cfg = config.khanelinix.cli-apps.spicetify;

  spicePkgs = spicetify-nix.packages.${pkgs.system}.default;
in
{
  options.khanelinix.cli-apps.spicetify = {
    enable = mkBoolOpt false "Whether or not to enable support for spicetify.";
  };

  imports = [ spicetify-nix.homeManagerModule ];

  config = mkIf cfg.enable {
    programs.spicetify = {
      enable = true;
      colorScheme = "blue";
      theme = spicePkgs.themes.catppuccin-macchiato;

      enabledCustomApps = with spicePkgs.apps; [
        lyrics-plus
        marketplace
        reddit
      ];

      enabledExtensions = with spicePkgs.extensions; [
        adblock
        autoSkip
        fullAppDisplay
        genre
        history
        playNext
        shuffle # shuffle+ (special characters are sanitized out of ext names)
        volumePercentage
      ];
    };
  };
}
