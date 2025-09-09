{
  config,
  lib,

  ...
}:
let
  cfg = config.khanelinix.theme.catppuccin;
in
{
  config = lib.mkIf cfg.enable {
    khanelinix.programs.graphical.wms.sway.settings = {
      set = {
        # Catppuccin Mocha colors
        "$rosewater" = "#f5e0dc";
        "$flamingo" = "#f2cdcd";
        "$pink" = "#f5c2e7";
        "$mauve" = "#cba6f7";
        "$red" = "#f38ba8";
        "$maroon" = "#eba0ac";
        "$peach" = "#fab387";
        "$yellow" = "#f9e2af";
        "$green" = "#a6e3a1";
        "$teal" = "#94e2d5";
        "$sky" = "#89dceb";
        "$sapphire" = "#74c7ec";
        "$blue" = "#89b4fa";
        "$lavender" = "#b4befe";
        "$text" = "#cdd6f4";
        "$subtext1" = "#bac2de";
        "$subtext0" = "#a6adc8";
        "$overlay2" = "#9399b2";
        "$overlay1" = "#7f849c";
        "$overlay0" = "#6c7086";
        "$surface2" = "#585b70";
        "$surface1" = "#45475a";
        "$surface0" = "#313244";
        "$base" = "#1e1e2e";
        "$mantle" = "#181825";
        "$crust" = "#11111b";
      };

      # childBorder background text indicator border
      "client.background" = "$base";
      "client.focused" = "$lavender $base $text $rosewater $lavender";
      "client.focused_inactive" = "$overlay0 $base $text $rosewater $overlay0";
      "client.unfocused" = "$overlay0 $base $text $rosewater $overlay0";
      "client.urgent" = "$peach $base $peach $overlay0 $peach";
      "client.placeholder" = "$overlay0 $base $text $overlay0 $overlay0";
    };

    # Keep the old structure for reference but convert to sway format above
    /*
      wayland.windowManager.sway = {
        config.colors = {
          background = "$base";

          focused = {
            childBorder = "$lavender";
            background = "$base";
            text = "$text";
            indicator = "$rosewater";
            border = "$lavender";
          };

          focusedInactive = {
            childBorder = "$overlay0";
            background = "$base";
            text = "$text";
            indicator = "$rosewater";
            border = "$overlay0";
          };

          unfocused = {
            childBorder = "$overlay0";
            background = "$base";
            text = "$text";
            indicator = "$rosewater";
            border = "$overlay0";
          };

          urgent = {
            childBorder = "$peach";
            background = "$base";
            text = "$peach";
            indicator = "$overlay0";
            border = "$peach";
          };

          placeholder = {
            childBorder = "$overlay0";
            background = "$base";
            text = "$text";
            indicator = "$overlay0";
            border = "$overlay0";
          };

          # bar
          # focusedBackground = "$base";
          # focusedStatusline = "$text";
          # focusedSeparator = "$base";
          # focusedWorkspace = {
          #   border = "$base";
          #   background = "$base";
          #   text = "$green";
          # };
          #
          # activeWorkspace = {
          #   border = "$base";
          #   background = "$base";
          #   text = "$blue";
          # };
          #
          # inactiveWorkspace = {
          #   border = "$base";
          #   background = "$base";
          #   text = "$surface1";
          # };
          #
          # urgentWorkspace = {
          #   border = "$base";
          #   background = "$base";
          #   text = "$peach";
          # };
          #
          # bindingMode = {
          #   border = "$base";
          #   background = "$base";
          #   text = "$surface1";
          # };
        };
      };
    */
  };
}
