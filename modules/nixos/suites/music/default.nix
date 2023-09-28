{ config
, lib
, options
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
      pkgs.khanelinix.yt-music
    ];

    khanelinix = {
      tools = {
        spicetify-cli = enabled;
      };

      user.extraGroups = [ "mpd" ];
    };

    # TODO: ?
    # services.mpd = {
    #   enable = true;
    #   user = config.khanelinix.user.name;
    # };
  };
}
