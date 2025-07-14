{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf getExe';

  cfg = config.khanelinix.hardware.yubikey;

  reload-yubikey =
    pkgs.writeShellScriptBin "reload-yubikey" # bash
      ''
        ${getExe' pkgs.gnupg "gpg-connect-agent"} "scd serialno" "learn --force" /bye
      '';
in
{
  options.khanelinix.hardware.yubikey = {
    enable = lib.mkEnableOption "Yubikey";
    enableSSHSupport = lib.mkEnableOption "SSH support for Yubikey";
  };

  config = mkIf cfg.enable {
    hardware.gpgSmartcards.enable = true;

    environment.systemPackages = with pkgs; [
      # Yubico's official tools
      yubikey-manager # cli
      # FIXME: insecure
      # yubikey-manager-qt # gui
      yubikey-personalization # cli
      yubico-piv-tool # cli
      yubioath-flutter # gui
      reload-yubikey
    ];

    services = {
      pcscd.enable = true;
      udev.packages = [ pkgs.yubikey-personalization ];
      yubikey-agent.enable = cfg.enableSSHSupport;
    };
  };
}
