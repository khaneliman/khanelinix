{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf mkForce;

  cfg = config.khanelinix.archetypes.wsl;
in
{
  options.khanelinix.archetypes.wsl = {
    enable = lib.mkEnableOption "the wsl archetype";
  };

  config = mkIf cfg.enable {
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

    khanelinix = {
      # Networking handled by host
      system.networking.enable = mkForce (!config.wsl.wslConf.network.generateResolvConf);
      # WSL Doesn't support `oomd`
      services.oomd.enable = mkForce false;

      # WSL-specific overrides - disable hardware-specific and desktop services
      hardware = {
        power.enable = mkForce false;
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
      };
    };

    services.chrony.enable = mkForce false;
  };
}
