{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.desktop.addons.sketchybar;
  zshAliases = {
    brew = ''command brew "$@" && sketchybar --trigger brew_update'';
    mas = ''command mas "$@" && sketchybar --trigger brew_update'';
    push = ''command git push && sketchybar --trigger git_push'';
  };
  fishAliases = {
    brew = ''command brew "$argv" && sketchybar --trigger brew_update'';
    mas = ''command mas "$argv" && sketchybar --trigger brew_update'';
    push = ''command git push && sketchybar --trigger git_push'';
  };
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

    khanelinix.home.extraOptions = {
      programs.fish.shellAliases = fishAliases;
      programs.zsh.shellAliases = zshAliases;
    };
  };
}
