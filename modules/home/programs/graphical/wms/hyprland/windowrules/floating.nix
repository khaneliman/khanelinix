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
          # Don't render `hyprbars` on tiling windows.
          # FIXME: not sure replacement
          # "match:float 0, plugin:hyprbars:no_bar on"

          "match:class Rofi, float on"
          "match:class viewnior, float on"
          "match:class feh, float on"
          "match:class wlogout, float on"
          "match:class file_progress, float on"
          "match:class confirm, float on"
          "match:class dialog, float on"
          "match:class download, float on"
          "match:class notification, float on"
          "match:class error, float on"
          "match:class splash, float on"
          "match:class confirmreset, float on"
          "match:class org.kde.polkit-kde-authentication-agent-1, float on"
          "match:class org.kde.ark, float on"
          "match:class ^(wdisplays)$, float on"
          "match:class ^(wdisplays)$, size 1100 600"
          "match:class ^(blueman-manager)$, float on"
          "match:class ^(nm-connection-editor)$, float on"
          "match:class it.mijorus.smile, float on"

          # floating terminal
          "match:title ^(floatterm)$, float on"
          "match:title ^(floatterm)$, size 1100 600"
          "match:title ^(floatterm)$, center on"
          "match:title ^(floatterm)$, animation slide"

          # calendar reminders
          "match:class ^(thunderbird)$, match:title .*(Reminders)$, float on"
          "match:class ^(thunderbird)$, match:title .*(Reminders)$, size 1100 600"
          "match:class ^(thunderbird)$, match:title .*(Reminders)$, move 78% 6%"
          "match:class ^(thunderbird)$, match:title .*(Reminders)$, pin on"

          # thunar file operation progress
          "match:class ^(thunar)$, match:title ^(File Operation Progress)$, float on"
          "match:class ^(thunar)$, match:title ^(File Operation Progress)$, size 800 600"
          "match:class ^(thunar)$, match:title ^(File Operation Progress)$, move 78% 6%"
          "match:class ^(thunar)$, match:title ^(File Operation Progress)$, pin on"

          "match:class ^(Godot)$, float on"
          "match:class ^(Godot)$, center on"

          "match:class ^(steam_app_0)$, match:title ^(World of Warcraft)$, min_size 5120 1440"
          "match:class ^(steam_app_0)$, match:title ^(World of Warcraft)$, center on"
          "match:class ^(steam_app_0)$, match:title ^(World of Warcraft)$, fullscreen on"

          # Workspace 8 (VM) layout
          # Pin small machine selection to right
          "match:class ^(virt-manager)$, match:title ^(Virtual Machine Manager)$, size 1000 1330"
          "match:class ^(virt-manager)$, match:title ^(Virtual Machine Manager)$, float on"
          "match:class ^(virt-manager)$, match:title ^(Virtual Machine Manager)$, move 80% 6%"
          "match:class ^(selfservice)$, float on"
          "match:class ^(selfservice)$, size 800 90%"
          "match:class ^(selfservice)$, move 100%-w-20 8%"

          # Size to fill rest of display
          "match:class ^(looking-glass-client)$, float on"
          "match:class ^(looking-glass-client)$, size 2360 1330"
          "match:class ^(looking-glass-client)$, move 25% 6%"
          "match:class ^(virt-manager)$, match:title ^.*(on QEMU/KVM)$, float on"
          "match:class ^(virt-manager)$, match:title ^.*(on QEMU/KVM)$, size 2360 1330"
          "match:class ^(virt-manager)$, match:title ^.*(on QEMU/KVM)$, move 25% 6%"
          "match:class ^(qemu)$, float on"
          "match:class ^(qemu)$, size 2360 1330"
          "match:class ^(qemu)$, move 25% 6%"
          # NOTE: hyprland bug atm causing it to move with monitor wake until it disappears
          # "match:class ^(Wfica)$, match:title ^(VT0-IT-47-D000).*, float on"
          # "match:class ^(Wfica)$, match:title ^(VT0-IT-47-D000).*, size 90% 90%"
          # "match:class ^(Wfica)$, match:title ^(VT0-IT-47-D000).*, move 20 8%"

          # make Firefox PiP window floating and sticky
          "match:title ^(Picture-in-Picture)$, float on"
          "match:title ^(Picture-in-Picture)$, pin on"

          # Lutris dialogs - center and constrain size to prevent off-screen positioning
          "match:class ^(net.lutris.Lutris)$, match:title ^(Select new location for the game)$, float on"
          "match:class ^(net.lutris.Lutris)$, match:title ^(Select new location for the game)$, center on"
          "match:class ^(net.lutris.Lutris)$, match:title ^(Select new location for the game)$, size 1200 600"
        ];
      };
    };
  };
}
