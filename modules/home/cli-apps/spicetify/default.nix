{
  options,
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.cli-apps.spicetify;
  spicePkgs = inputs.spicetify-nix.packages.${pkgs.system}.default;
in {
  options.khanelinix.cli-apps.spicetify = with types; {
    enable = mkBoolOpt false "Whether or not to enable support for spicetify.";
  };

  imports = [inputs.spicetify-nix.homeManagerModule];

  config = mkIf cfg.enable {
    # configure spicetify :)
    programs.spicetify = {
      enable = true;
      theme = spicePkgs.themes.catppuccin-macchiato;
      colorScheme = "blue";

      enabledExtensions = with spicePkgs.extensions; [
        fullAppDisplay
        shuffle # shuffle+ (special characters are sanitized out of ext names)
      ];
    };
  };
}
