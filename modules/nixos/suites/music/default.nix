{ options
, config
, lib
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt enabled;

  cfg = config.khanelinix.suites.music;
in
{
  options.khanelinix.suites.music = {
    enable = mkBoolOpt false "Whether or not to enable music configuration.";
  };

  config = mkIf cfg.enable {
    # services.mpd = {
    #   enable = true;
    #   user = config.khanelinix.user.name;
    # };

    khanelinix.user.extraGroups = [ "mpd" ];

    environment.systemPackages = with pkgs; [
      ardour
      cadence
      mpd-notification
      mpdevil
      mpdris2
      # ncmpcpp
      spotify
      tageditor
      youtube-music
    ];

    khanelinix = {
      apps = {
        yt-music = enabled;
      };

      tools = {
        spicetify-cli = enabled;
      };
    };
  };
}
