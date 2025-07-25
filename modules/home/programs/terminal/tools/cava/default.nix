{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.terminal.tools.cava;
in
{
  options.khanelinix.programs.terminal.tools.cava = {
    enable = lib.mkEnableOption "cava";
  };

  config = mkIf cfg.enable {
    home.shellAliases = {
      cava = "TERM=st-256color cava";
    };

    programs.cava = {
      enable = true;
      package = if pkgs.stdenv.hostPlatform.isLinux then pkgs.cava else pkgs.emptyDirectory;

      settings =
        {
          general = {
            framerate = 60;
            autosens = 1;
            overshoot = 20;
            sensitivity = 100;
            bars = 0;
            bar_width = 2;
            bar_spacing = 1;
            bar_height = 32;
            lower_cutoff_freq = 50;
            higher_cutoff_freq = 10000;
            sleep_timer = 0;
          };

          output = {
            method = "ncurses";
            orientation = "bottom";
            channels = "stereo";
            mono_option = "average";
            reverse = 0;
            raw_target = "/dev/stdout";
            data_format = "binary";
            bit_format = "16bit";
            ascii_max_range = 1000;
            bar_delimiter = 59;
            frame_delimiter = 10;
            sdl_width = 1000;
            sdl_height = 500;
            sdl_x = -1;
            sdl_y = -1;
            xaxis = "none";
            alacritty_sync = 0;
            vertex_shader = "pass_through.vert";
            fragment_shader = "normalized_bars.frag";
            continuous_rendering = 0;
          };

          smoothing = {
            integral = 77;
            monstercat = 0;
            waves = 0;
            gravity = 100;
            ignore = 0;
            noise_reduction = 77;
          };

          eq = {
            "1" = 1; # bass
            "2" = 1;
            "3" = 1; # midtone
            "4" = 1;
            "5" = 1; # treble
          };
        }
        // lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
          input = {
            method = "pulse";
            source = "auto";
          };
        }
        // lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
          input = {
            method = "portaudio";
            source = "Background Music";
          };
        };
    };
  };
}
