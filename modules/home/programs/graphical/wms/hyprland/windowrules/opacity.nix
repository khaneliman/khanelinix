{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.khanelinix.programs.graphical.wms.hyprland;
in
{
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      settings = {
        # See https://wiki.hyprland.org/Configuring/Window-Rules/ for more
        windowrule = [
          "opaque, class:^(virt-manager)$,title:.*(on QEMU).*"
          "opaque, class:^(looking-glass-client)$"
          "opaque, title:^(.*(Twitch|TNTdrama|YouTube|Bally Sports|Video Entertainment|Plex)).*(Firefox).*$"
          "dimaround, class:^(gcr-prompter)$"
        ];
      };
    };
  };
}
