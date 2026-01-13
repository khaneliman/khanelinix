{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  inherit (lib.khanelinix) mkBoolOpt;

  cfg = config.khanelinix.programs.graphical.mangohud;
in
{
  options.khanelinix.programs.graphical.mangohud = {
    enable = mkEnableOption "mangohud";
    enableSessionWide = mkBoolOpt true "Enable MangoHud for all applications";
  };

  config = mkIf cfg.enable {
    programs.mangohud = {
      enable = true;
      package = pkgs.mangohud;
      inherit (cfg) enableSessionWide;

      settings = {
        # Output
        output_folder = config.home.homeDirectory + "/Documents/mangohud";

        # Performance metrics
        fps = true;
        fps_limit_method = "late";
        frametime = true;
        frame_timing = 1;

        # GPU info
        gpu_stats = true;
        gpu_temp = true;
        gpu_core_clock = true;
        gpu_mem_clock = true;
        gpu_power = true;
        gpu_load_change = true;
        gpu_load_value = [
          50
          90
        ];
        gpu_load_color = lib.mkDefault [
          "39F900"
          "FDFD09"
          "B22222"
        ];

        # CPU info
        cpu_stats = true;
        cpu_temp = true;
        cpu_power = true;
        cpu_mhz = true;
        cpu_load_change = true;
        cpu_load_value = [
          50
          90
        ];
        cpu_load_color = lib.mkDefault [
          "39F900"
          "FDFD09"
          "B22222"
        ];

        # System info
        ram = true;
        vram = true;
        swap = true;

        # Wine/Proton
        wine = true;
        winesync = true;

        # Display
        position = "top-left";
        background_alpha = lib.mkDefault 0.5;
        font_size = lib.mkDefault 24;
        text_outline = true;
        text_outline_thickness = 1.5;

        # Toggle controls
        toggle_fps_limit = "Shift_R+F1";
        toggle_hud = "Shift_R+F12";
        toggle_logging = "Shift_L+F2";
        reload_cfg = "Shift_L+F5";

        # Logging
        log_duration = 0;
        autostart_log = 0;

        blacklist = [
          "vinegar"
          "sober"
          "RobloxPlayerBeta.exe"
          "RobloxStudioBeta.exe"
        ];
      };
    };
  };
}
