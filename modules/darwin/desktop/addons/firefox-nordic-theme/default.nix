{ options, config, lib, pkgs, ... }:

with lib;
with lib.internal;
let
  cfg = config.khanelinix.desktop.addons.firefox-nordic-theme;
  profileDir = ".mozilla/firefox/${config.khanelinix.user.name}";
in
{
  options.khanelinix.desktop.addons.firefox-nordic-theme = with types; {
    enable = mkBoolOpt false "Whether to enable the Nordic theme for firefox.";
  };

  config = mkIf cfg.enable {
    khanelinix.apps.firefox = {
      extraConfig = builtins.readFile
        "${pkgs.khanelinix.firefox-nordic-theme}/configuration/user.js";
      userChrome = ''
        @import "${pkgs.khanelinix.firefox-nordic-theme}/userChrome.css";
      '';
    };
  };
}
