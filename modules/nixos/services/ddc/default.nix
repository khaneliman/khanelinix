{
  lib,
  pkgs,
  config,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.services.ddc;
in
{
  imports = [
    (lib.mkRenamedOptionModule
      [ "khanelinix" "services" "ddccontrol" "enable" ]
      [ "khanelinix" "services" "ddc" "enable" ]
    )
  ];

  options.khanelinix.services.ddc = {
    enable = lib.mkEnableOption "DDC display control";
  };

  config = mkIf cfg.enable {

    environment.systemPackages = with pkgs; [
      ddcui
      ddcutil
    ];

    services.ddccontrol = {
      # DDCControl documentation
      # See: https://github.com/ddccontrol/ddccontrol
      enable = true;
    };
  };
}
