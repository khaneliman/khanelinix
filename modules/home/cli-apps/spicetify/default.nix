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

  spicePkgs = spicetify-nix.legacyPackages.${pkgs.system};
in
{
  options.khanelinix.cli-apps.spicetify = {
    enable = mkBoolOpt false "Whether or not to enable support for spicetify.";
  };

  config = mkIf cfg.enable {
    programs.spicetify = {
      enable = true;
      colorScheme = "macchiato";
      theme = spicePkgs.themes.catppuccin;

      enabledCustomApps = with spicePkgs.apps; [
        lyrics-plus
        marketplace
        reddit
      ];

      enabledExtensions = with spicePkgs.extensions; [
        adblock
        autoSkip
        fullAppDisplay
        history
        playNext
        shuffle # shuffle+ (special characters are sanitized out of ext names)
        volumePercentage
      ];
    };
  };
}
