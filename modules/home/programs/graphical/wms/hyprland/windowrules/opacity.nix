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
        window_rule = [
          {
            match.class = "^(virt-manager)$";
            match.title = ".*(on QEMU).*";
            opaque = true;
          }
          {
            match.class = "^(looking-glass-client)$";
            opaque = true;
          }
          {
            match.title = "^(.*(Twitch|TNTdrama|YouTube|Bally Sports|Video Entertainment|Plex)).*(Firefox).*$";
            opaque = true;
          }
          {
            match.class = "^(gcr-prompter)$";
            dim_around = true;
          }
        ];
      };
    };
  };
}
