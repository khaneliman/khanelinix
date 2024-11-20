{
  config,
  lib,
  pkgs,

  ...
}:
let
  cfg = config.khanelinix.desktop.addons.jankyborders;
in
{
  options.khanelinix.desktop.addons.jankyborders = {
    enable = flake.inputs.self.lib.khanelinix.mkBoolOpt false "Whether to enable jankyborders in the desktop environment.";
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.jankyborders;
      defaultText = lib.literalExpression "pkgs.jankyborders";
      description = "The jankyborders package to use.";
      example = lib.literalExpression "pkgs.khanelinix.jankyborders";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ jankyborders ];

    khanelinix.home.configFile = {
      "borders/bordersrc".source =
        pkgs.writeShellScript "bordersrc" # bash
          ''
            options=(
            	style=round
            	width=6.0
            	hidpi=off
            	active_color=0xff7793d1
            	inactive_color=0xff5e6798
            	background_color=0x302c2e34
            	blur_radius=25
            )

            ${lib.getExe cfg.package} "''${options[@]}"
          '';
    };
  };
}
