{
  config,
  lib,
  ...
}:
let
  cfg = config.khanelinix.programs.graphical.addons.swappy;
in
{
  options.khanelinix.programs.graphical.addons.swappy = {
    enable = lib.mkEnableOption "Swappy in the desktop environment";
  };

  config = lib.mkIf cfg.enable {
    # Placeholder for screenshots folder
    home.file."Pictures/screenshots/.keep".text = "";

    programs.swappy = {
      enable = true;

      settings = {
        Default = {
          save_dir = "$HOME/Pictures/screenshots/";
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
