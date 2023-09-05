{ options
, config
, lib
, pkgs
, inputs
, ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.internal) mkBoolOpt;
  inherit (inputs) spicetify-nix;
  cfg = config.khanelinix.cli-apps.spicetify;
  spicePkgs = spicetify-nix.packages.${pkgs.system}.default;
in
{
  options.khanelinix.cli-apps.spicetify = with types; {
    enable = mkBoolOpt false "Whether or not to enable support for spicetify.";
  };

  imports = [ spicetify-nix.homeManagerModule ];

  config = mkIf cfg.enable {
    # configure spicetify :)
    programs.spicetify = {
      enable = true;
      theme = spicePkgs.themes.catppuccin-macchiato;
      colorScheme = "blue";

      enabledCustomApps = with spicePkgs.apps; [
        marketplace
        reddit
        lyrics-plus
      ];

      enabledExtensions = with spicePkgs.extensions; [
        adblock
        autoSkip
        playNext
        volumePercentage
        history
        genre
        fullAppDisplay
        shuffle # shuffle+ (special characters are sanitized out of ext names)
      ];
    };
  };
}
