{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.desktop.addons.jankyborders;
in
{
  options.${namespace}.desktop.addons.jankyborders = {
    enable =
      lib.${namespace}.mkBoolOpt false
        "Whether to enable jankyborders in the desktop environment.";
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.jankyborders;
      defaultText = lib.literalExpression "pkgs.jankyborders";
      description = "The jankyborders package to use.";
      example = lib.literalExpression "pkgs.${namespace}.jankyborders";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ jankyborders ];

    ${namespace}.home.configFile = {
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
