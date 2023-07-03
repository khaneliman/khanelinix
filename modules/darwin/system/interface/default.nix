{ options, config, pkgs, lib, ... }:

with lib;
with lib.internal;
let cfg = config.khanelinix.system.interface;
in
{
  options.khanelinix.system.interface = with types; {
    enable = mkEnableOption "macOS interface";
  };

  config = mkIf cfg.enable {
    system.defaults = {
      dock.autohide = true;

      finder = {
        AppleShowAllExtensions = true;
        FXEnableExtensionChangeWarning = false;
      };

      NSGlobalDomain = {
        _HIHideMenuBar = true;
        AppleShowScrollBars = "Always";
      };
    };
  };
}
