{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf getExe';
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.hardware.yubikey;

  reload-yubikey =
    pkgs.writeShellScriptBin "reload-yubikey" # bash
      ''
        ${getExe' pkgs.gnupg "gpg-connect-agent"} "scd serialno" "learn --force" /bye
      '';
in
{
  options.${namespace}.hardware.yubikey = {
    enable = mkBoolOpt false "Whether or not to enable Yubikey.";
    enableSSHSupport = mkBoolOpt false "Whether or not to enable SSH support for Yubikey.";
  };

  config = mkIf cfg.enable {
    hardware.gpgSmartcards.enable = true;

    environment.systemPackages = with pkgs; [
      # Yubico's official tools
      # FIXME: broken nixpkgs
      # yubikey-manager # cli
      # yubikey-manager-qt # gui
      yubikey-personalization # cli
      yubikey-personalization-gui # gui
      yubico-piv-tool # cli
      #yubioath-flutter # gui
      reload-yubikey
    ];

    programs.ssh.startAgent = !cfg.enableSSHSupport;

    services = {
      pcscd.enable = true;
      udev.packages = [ pkgs.yubikey-personalization ];
      yubikey-agent.enable = cfg.enableSSHSupport;
    };
  };
}
