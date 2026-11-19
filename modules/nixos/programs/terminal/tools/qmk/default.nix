{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.terminal.tools.qmk;
in
{
  imports = [
    (lib.mkRenamedOptionModule
      [ "khanelinix" "tools" "qmk" "enable" ]
      [ "khanelinix" "programs" "terminal" "tools" "qmk" "enable" ]
    )
  ];

  options.khanelinix.programs.terminal.tools.qmk = {
    enable = lib.mkEnableOption "QMK";
  };

  config = mkIf cfg.enable {
    # QMK documentation
    # See: https://docs.qmk.fm/
    environment.systemPackages = with pkgs; [ qmk ];

    services.udev.packages = with pkgs; [ qmk-udev-rules ];
  };
}
