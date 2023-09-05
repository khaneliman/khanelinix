{ options
, config
, lib
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt enabled;

  cfg = config.khanelinix.suites.video;
in
{
  options.khanelinix.suites.video = {
    enable = mkBoolOpt false "Whether or not to enable video configuration.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      mediainfo-gui
    ];

    khanelinix = {
      apps = {
        obs = enabled;
        # TODO: enable when not broken
        # pitivi = enabled;
        vlc = enabled;
      };
    };
  };
}
