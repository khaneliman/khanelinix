{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.khanelinix.services.sunshine;
  userName = config.khanelinix.user.name;
in
{
  options.khanelinix.services.sunshine = {
    enable = mkEnableOption "Sunshine game stream host";
  };

  config = mkIf cfg.enable {
    services.avahi.enable = mkIf (!config.khanelinix.services.avahi.enable) false;

    services.sunshine = {
      enable = true;
      autoStart = true;
      capSysAdmin = true;
      openFirewall = true;
    };

    hardware.uinput.enable = true;

    users.users.${userName}.extraGroups = [ "uinput" ];
  };
}
