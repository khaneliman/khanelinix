{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.desktop.addons.sketchybar;
in
{
  options.khanelinix.desktop.addons.sketchybar = with types; {
    enable = mkBoolOpt false "Whether or not to enable sketchybar.";
  };

  config = mkIf cfg.enable {
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
