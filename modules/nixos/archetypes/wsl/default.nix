{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf mkForce mkMerge;

  cfg = config.khanelinix.archetypes.wsl;
in
{
  options.khanelinix.archetypes.wsl = {
    enable = lib.mkEnableOption "the wsl archetype";
    enableGUI = lib.mkEnableOption "GUI support in WSL (enables desktop portals, graphics, theming)";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      environment = {
        sessionVariables = {
          BROWSER = "wsl-open";
        };

        systemPackages = with pkgs; [
          dos2unix
          wsl-open
          wslu
        ];
      };

      # Limit to main fonts only
      fonts.packages = mkForce (
        with pkgs;
        [
          monaspace
          nerd-fonts.symbols-only
        ]
      );

      services = {
        # Power management services not applicable in WSL
        power-profiles-daemon.enable = mkForce false;
        upower.enable = mkForce false;
        chrony.enable = mkForce false;
      };

      khanelinix = {
        # Networking handled by host
        system.networking.enable = mkForce (!config.wsl.wslConf.network.generateResolvConf);
        # WSL Doesn't support `oomd`
        services.oomd.enable = mkForce false;

        # WSL-specific overrides - disable hardware-specific and desktop services
        hardware = {
          power.enable = mkForce false;
          fans.enable = mkForce false;
        };

        programs = {
          terminal = {
            tools = {
              # Network monitoring less useful in WSL
              bandwhich.enable = mkForce false;
            };
          };
        };

        security = {
          # Antivirus not needed in WSL
          clamav.enable = mkForce false;
          # USB devices not available in WSL
          usbguard.enable = mkForce false;
        };

        services = {
          # Display management not applicable in WSL
          ddccontrol.enable = mkForce false;
          # Printing not applicable in WSL
          printing.enable = mkForce false;
          # LACT for AMD GPU control not needed in WSL
          lact.enable = mkForce false;
        };
      };
    }

    # If no GUI support enabled, disable bloated gui components
    (mkIf (!cfg.enableGUI) {
      hardware.graphics = {
        enable = mkForce false;
        enable32Bit = mkForce false;
      };

      services = {
        pipewire.enable = mkForce false;
        pulseaudio.enable = mkForce false;
      };

      services = {
        xserver.enable = mkForce false;
        gnome.gnome-settings-daemon.enable = mkForce false;
        colord.enable = mkForce false;
        dbus.packages = mkForce [ ];
      };

      xdg.portal = {
        enable = mkForce false;
        extraPortals = mkForce [ ];
      };

      khanelinix.theme = {
        gtk.enable = mkForce false;
        qt.enable = mkForce false;
      };
    })
  ]);
}
