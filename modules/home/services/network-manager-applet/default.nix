{ config, lib, ... }:
{
  config = lib.mkIf config.services.network-manager-applet.enable {
    xdg.configFile."autostart/nm-applet.desktop".text = ''
      [Desktop Entry]
      Hidden=true
    '';
  };
}
