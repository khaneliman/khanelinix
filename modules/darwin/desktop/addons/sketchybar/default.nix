{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.desktop.addons.sketchybar;

in
{
  options.khanelinix.desktop.addons.sketchybar = {
    enable = mkBoolOpt false "Whether or not to enable sketchybar.";
  };

  config = mkIf cfg.enable {
    homebrew = {
      brews = [ "cava" "jq" ];
      casks = [ "background-music" ];
    };

    services.sketchybar = {
      enable = true;
      package = pkgs.sketchybar;
      extraPackages = with pkgs; [
        coreutils
        curl
        gh
        gnugrep
        gnused
        jq
      ];

      # TODO: need to update nixpkg to support complex configurations
      # config = ''
      #
      # '';
    };
  };
}
