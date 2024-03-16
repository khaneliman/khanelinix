{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf getExe;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.desktop.addons.jankyborders;
in
{
  options.khanelinix.desktop.addons.jankyborders = {
    enable =
      mkBoolOpt false "Whether to enable jankyborders in the desktop environment.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs.khanelinix; [
      jankyborders
    ];

    khanelinix.home.configFile = {
      "borders/bordersrc".source = pkgs.writeShellScript "bordersrc" /*bash*/ ''
        options=(
        	style=round
        	width=6.0
        	hidpi=off
        	active_color=0xff7793d1
        	inactive_color=0xff5e6798
        	background_color=0x302c2e34
        	blur_radius=25
        )

        ${getExe pkgs.khanelinix.jankyborders} "''${options[@]}"
      '';
    };
  };
}
