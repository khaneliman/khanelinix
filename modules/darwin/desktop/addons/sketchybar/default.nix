{ options
, config
, lib
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.desktop.addons.sketchybar;
  zshAliases = with pkgs; {
    brew = ''command brew "$@" && ${lib.getExe sketchybar} --trigger brew_update'';
    mas = ''command mas "$@" && ${lib.getExe sketchybar} --trigger brew_update'';
    push = ''command git push && ${lib.getExe sketchybar} --trigger git_push'';
  };
  fishAliases = with pkgs; {
    brew = ''command brew "$argv" && ${lib.getExe sketchybar} --trigger brew_update'';
    mas = ''command mas "$argv" && ${lib.getExe sketchybar} --trigger brew_update'';
    push = ''command git push && ${lib.getExe sketchybar} --trigger git_push'';
  };
in
{
  options.khanelinix.desktop.addons.sketchybar = {
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
