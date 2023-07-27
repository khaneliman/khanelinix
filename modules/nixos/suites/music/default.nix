{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.suites.music;
in {
  options.khanelinix.suites.music = with types; {
    enable = mkBoolOpt false "Whether or not to enable music configuration.";
  };

  config = mkIf cfg.enable {
    # services.mpd = {
    #   enable = true;
    #   user = config.khanelinix.user.name;
    # };

    khanelinix.user.extraGroups = ["mpd"];

    environment.systemPackages = with pkgs; [
      ardour
      cadence
      mpd-notification
      mpdevil
      mpdris2
      # ncmpcpp
      spotify
    ];

    khanelinix = {
      apps = {
        yt-music = enabled;
      };
    };
  };
}
