{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.hardware.yubikey;
in
{
  options.khanelinix.hardware.yubikey = {
    enable = mkBoolOpt false "Whether or not to enable Yubikey.";
  };

  config = mkIf cfg.enable {
    hardware.gpgSmartcards.enable = true;

    environment.systemPackages = with pkgs; [
      # Yubico's official tools
      yubikey-manager # cli
      yubikey-manager-qt # gui
      yubikey-personalization # cli
      yubikey-personalization-gui # gui
      yubico-piv-tool # cli
      #yubioath-flutter # gui
    ];

    programs = {
      ssh.startAgent = false;
      gnupg.agent = {
        enable = true;
        enableSSHSupport = true;
      };
    };

    services = {
      pcscd.enable = true;
      udev.packages = [ pkgs.yubikey-personalization ];
      yubikey-agent.enable = true;
    };
  };
}
