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
          # Don't render `hyprbars` on tiling windows.
          # FIXME: not sure replacement
          # "match:float 0, plugin:hyprbars:no_bar on"

          {
            match.class = "Rofi|viewnior|feh|wlogout|file_progress|confirm|dialog|download|notification|error|splash|confirmreset|org.kde.polkit-kde-authentication-agent-1|org.kde.ark|^(wdisplays)$|^(blueman-manager)$|^(nm-connection-editor)$|it.mijorus.smile";
            float = true;
          }
          {
            match.class = "^(wdisplays)$";
            size = "1100 600";
          }

          # floating terminal
          {
            match.title = "^(floatterm)$";
            float = true;
          }
          {
            match.title = "^(floatterm)$";
            size = "1100 600";
          }
          {
            match.title = "^(floatterm)$";
            center = true;
          }
          {
            match.title = "^(floatterm)$";
            animation = "slide";
          }

          # calendar reminders
          {
            match.class = "^(thunderbird)$";
            match.title = ".*(Reminders)$";
            float = true;
          }
          {
            match.class = "^(thunderbird)$";
            match.title = ".*(Reminders)$";
            size = "1100 600";
          }
          {
            match.class = "^(thunderbird)$";
            match.title = ".*(Reminders)$";
            move = "78% 6%";
          }
          {
            match.class = "^(thunderbird)$";
            match.title = ".*(Reminders)$";
            pin = true;
          }

          # thunar file operation progress
          {
            match.class = "^(thunar)$";
            match.title = "^(File Operation Progress)$";
            float = true;
          }
          {
            match.class = "^(thunar)$";
            match.title = "^(File Operation Progress)$";
            size = "800 600";
          }
          {
            match.class = "^(thunar)$";
            match.title = "^(File Operation Progress)$";
            move = "78% 6%";
          }
          {
            match.class = "^(thunar)$";
            match.title = "^(File Operation Progress)$";
            pin = true;
          }

          {
            match.class = "^(Godot)$";
            float = true;
          }
          {
            match.class = "^(Godot)$";
            center = true;
          }

          {
            match.class = "^(steam_app_0)$";
            match.title = "^(World of Warcraft)$";
            min_size = "5120 1440";
          }
          {
            match.class = "^(steam_app_0)$";
            match.title = "^(World of Warcraft)$";
            center = true;
          }
          {
            match.class = "^(steam_app_0)$";
            match.title = "^(World of Warcraft)$";
            fullscreen = true;
          }

          # Workspace 8 (VM) layout
          # Pin small machine selection to right
          {
            match.class = "^(virt-manager)$";
            match.title = "^(Virtual Machine Manager)$";
            size = "1000 1330";
          }
          {
            match.class = "^(virt-manager)$";
            match.title = "^(Virtual Machine Manager)$";
            float = true;
          }
          {
            match.class = "^(virt-manager)$";
            match.title = "^(Virtual Machine Manager)$";
            move = "80% 6%";
          }
          {
            match.class = "^(selfservice)$";
            float = true;
          }
          {
            match.class = "^(selfservice)$";
            size = "800 90%";
          }
          {
            match.class = "^(selfservice)$";
            move = "100%-w-20 8%";
          }

          # Size to fill rest of display
          {
            match.class = "^(looking-glass-client)$";
            float = true;
          }
          {
            match.class = "^(looking-glass-client)$";
            size = "2360 1330";
          }
          {
            match.class = "^(looking-glass-client)$";
            move = "25% 6%";
          }
          {
            match.class = "^(virt-manager)$";
            match.title = "^.*(on QEMU/KVM)$";
            float = true;
          }
          {
            match.class = "^(virt-manager)$";
            match.title = "^.*(on QEMU/KVM)$";
            size = "2360 1330";
          }
          {
            match.class = "^(virt-manager)$";
            match.title = "^.*(on QEMU/KVM)$";
            move = "25% 6%";
          }
          {
            match.class = "^(qemu)$";
            float = true;
          }
          {
            match.class = "^(qemu)$";
            size = "2360 1330";
          }
          {
            match.class = "^(qemu)$";
            move = "25% 6%";
          }
          # NOTE: hyprland bug atm causing it to move with monitor wake until it disappears
          # "match:class ^(Wfica)$, match:title ^(VT0-IT-47-D000).*, float on"
          # "match:class ^(Wfica)$, match:title ^(VT0-IT-47-D000).*, size 90% 90%"
          # "match:class ^(Wfica)$, match:title ^(VT0-IT-47-D000).*, move 20 8%"

          # make Firefox PiP window floating and sticky
          {
            match.title = "^(Picture-in-Picture)$";
            float = true;
          }
          {
            match.title = "^(Picture-in-Picture)$";
            pin = true;
          }

          # Lutris dialogs - center and constrain size to prevent off-screen positioning
          {
            match.class = "^(net.lutris.Lutris)$";
            match.title = "^(Select new location for the game)$";
            float = true;
          }
          {
            match.class = "^(net.lutris.Lutris)$";
            match.title = "^(Select new location for the game)$";
            center = true;
          }
          {
            match.class = "^(net.lutris.Lutris)$";
            match.title = "^(Select new location for the game)$";
            size = "1200 600";
          }
        ];
      };
    };
  };
}
