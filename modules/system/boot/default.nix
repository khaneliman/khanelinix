{ options
, config
, pkgs
, lib
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.system.boot;
in
{
  options.khanelinix.system.boot = with types; {
    enable = mkBoolOpt false "Whether or not to enable booting.";
  };

  config = mkIf cfg.enable {
    boot = {
      loader = {
        # https://github.com/NixOS/nixpkgs/blob/c32c39d6f3b1fe6514598fa40ad2cf9ce22c3fb7/nixos/modules/system/systemd-boot/systemd-boot.nix#L66
        systemd-boot = {
          enable = true;
          configurationLimit = 20;
          editor = false;
        };
        efi = {
          canTouchEfiVariables = true;
          efiSysMountPoint = "/boot/efi";
        };
      };

      plymouth = {
        enable = true;
        themePackages = [ pkgs.khanelinix.catppuccin-plymouth ];
        theme = "catppuccin-macchiato";
        # font = "${pkgs.noto-fonts}/share/fonts/truetype/noto/NotoSans-Light.ttf";
      };
    };
  };
}
