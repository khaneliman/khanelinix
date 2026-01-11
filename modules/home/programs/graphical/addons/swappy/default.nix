{
  config,
  lib,
  ...
}:
let
  cfg = config.khanelinix.programs.graphical.addons.swappy;
  picturesDir =
    if config.xdg.userDirs.enable then
      config.xdg.userDirs.pictures
    else
      "${config.home.homeDirectory}/Pictures";
in
{
  options.khanelinix.programs.graphical.addons.swappy = {
    enable = lib.mkEnableOption "Swappy in the desktop environment";
  };

  config = lib.mkIf cfg.enable {
    # Placeholder for screenshots folder
    home.file."${lib.removePrefix "${config.home.homeDirectory}/" picturesDir}/screenshots/.keep".text =
      "";

    programs.swappy = {
      enable = true;

      settings = {
        Default = {
          save_dir = "${picturesDir}/screenshots/";
          save_filename_format = "swappy-%Y%m%d-%H%M%S.png";
          show_panel = false;
          line_size = 5;
          text_size = 20;
          text_font = "sans-serif";
          paint_mode = "brush";
          early_exit = false;
          fill_shape = false;
        };
      };
    };
  };
}
