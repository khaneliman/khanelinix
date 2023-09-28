{ options
, config
, pkgs
, lib
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;
  cfg = config.khanelinix.system.boot;
in
{
  options.khanelinix.system.boot = {
    enable = mkBoolOpt false "Whether or not to enable booting.";
    secureBoot = mkBoolOpt false "Whether or not to enable secure boot.";
    plymouth = mkBoolOpt false "Whether or not to enable plymouth boot splash.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs;  [
      efibootmgr
      efitools
      efivar
      fwupd
    ] ++ lib.optionals cfg.secureBoot [
      sbctl
    ];

    boot = {
      kernelParams = lib.optionals cfg.plymouth [ "quiet" ];

      lanzaboote = mkIf cfg.secureBoot {
        enable = true;
        pkiBundle = "/etc/secureboot";
      };

      loader = {
        efi = {
          canTouchEfiVariables = true;
          efiSysMountPoint = "/boot";
        };

        # https://github.com/NixOS/nixpkgs/blob/c32c39d6f3b1fe6514598fa40ad2cf9ce22c3fb7/nixos/modules/system/systemd-boot/systemd-boot.nix#L66
        systemd-boot = {
          enable = !cfg.secureBoot;
          configurationLimit = 20;
          editor = false;
        };
      };

      plymouth = {
        enable = cfg.plymouth;
        themePackages = [ pkgs.catppuccin-plymouth ];
        theme = "catppuccin-macchiato";
        # font = "${pkgs.noto-fonts}/share/fonts/truetype/noto/NotoSans-Light.ttf";
      };
    };

    services.fwupd.enable = true;
  };
}
