{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.graphical.apps.prismlauncher;
in
{
  options.khanelinix.programs.graphical.apps.prismlauncher = {
    enable = lib.mkEnableOption "prismlauncher";
  };

  config = mkIf cfg.enable {
    programs.prismlauncher.enable = true;
  };
}
