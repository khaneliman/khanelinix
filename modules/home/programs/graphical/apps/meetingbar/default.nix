{
  config,
  lib,
  pkgs,

  ...
}:
let
  cfg = config.khanelinix.programs.graphical.apps.meetingbar;
in
{
  options.khanelinix.programs.graphical.apps.meetingbar.enable = lib.mkEnableOption "MeetingBar";

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isDarwin;
        message = "MeetingBar is only supported on Darwin.";
      }
    ];

    home.packages = [ pkgs.meetingbar ];

    targets.darwin.defaults."leits.MeetingBar" = {
      launchAtLogin = true;
    };
  };
}
