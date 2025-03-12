{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.${namespace}.programs.graphical.wms.hyprland;
in
{
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      settings = {
        # See https://wiki.hyprland.org/Configuring/Window-Rules/ for more
        windowrulev2 = [
          "float, class:Rofi"
          "float, class:viewnior"
          "float, class:feh"
          "float, class:wlogout"
          "float, class:file_progress"
          "float, class:confirm"
          "float, class:dialog"
          "float, class:download"
          "float, class:notification"
          "float, class:error"
          "float, class:splash"
          "float, class:confirmreset"
          "float, class:org.kde.polkit-kde-authentication-agent-1"
          "float, class:org.kde.ark"
          "float, class:^(wdisplays)$"
          "size 1100 600, class:^(wdisplays)$"
          "float, class:^(blueman-manager)$"
          "float, class:^(nm-connection-editor)$"
          "float, class:it.mijorus.smile"

          # floating terminal
          "float, title:^(floatterm)$"
          "size 1100 600, title:^(floatterm)$"
          "move center, title:^(floatterm)$"
          "animation slide, title:^(floatterm)$"

          # calendar reminders
          "float, class:^(thunderbird)$,title:.*(Reminders)$"
          "size 1100 600, class:^(thunderbird)$,title:.*(Reminders)$"
          "move 78% 6%, class:^(thunderbird)$,title:.*(Reminders)$"
          "pin, class:^(thunderbird)$,title:.*(Reminders)$"

          # thunar file operation progress
          "float, class:^(thunar)$,title:^(File Operation Progress)$"
          "size 800 600, class:^(thunar)$,title:^(File Operation Progress)$"
          "move 78% 6%, class:^(thunar)$,title:^(File Operation Progress)$"
          "pin, class:^(thunar)$,title:^(File Operation Progress)$"

          "minsize 5120 1440, class:^(steam_app_0)$, title:^(World of Warcraft)$"
          "center, class:^(steam_app_0)$, title:^(World of Warcraft)$"
          "fullscreen, class:^(steam_app_0)$, title:^(World of Warcraft)$"

          # Workspace 8 (VM) layout
          "size 1000 1330, class:^(virt-manager)$, title:^(Virtual Machine Manager)$"
          "float, class:^(virt-manager)$, title:^(Virtual Machine Manager)$"
          "move 80% 6%, class:^(virt-manager)$, title:^(Virtual Machine Manager)$"
          "float, class:^(looking-glass-client)$"
          "size 2360 1330, class:^(looking-glass-client)$"
          "move 25% 6%, class:^(looking-glass-client)$"
          "float,  class:^(virt-manager)$, title:^.*(on QEMU/KVM)$"
          "size 2360 1330, class:^(virt-manager)$, title:^.*(on QEMU/KVM)$"
          "move 25% 6%, class:^(virt-manager)$, title:^.*(on QEMU/KVM)$"
          "float,  class:^(qemu)$"
          "size 2360 1330, class:^(qemu)$"
          "move 25% 6%, class:^(qemu)$"

          # make Firefox PiP window floating and sticky
          "float, title:^(Picture-in-Picture)$"
          "pin, title:^(Picture-in-Picture)$"
        ];
      };
    };
  };
}
