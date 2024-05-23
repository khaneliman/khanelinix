{
  config,
  lib,
  pkgs,
  inputs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  inherit (inputs) spicetify-nix;

  cfg = config.${namespace}.programs.terminal.media.spicetify;

  spicePkgs = spicetify-nix.legacyPackages.${pkgs.system};
in
{
  options.${namespace}.programs.terminal.media.spicetify = {
    enable = mkBoolOpt false "Whether or not to enable support for spicetify.";
  };

  config = mkIf cfg.enable {
    programs.spicetify = {
      enable = true;
      # TODO: move to theme module
      colorScheme = "macchiato";
      theme = spicePkgs.themes.catppuccin;

      enabledCustomApps = with spicePkgs.apps; [
        lyricsPlus
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
