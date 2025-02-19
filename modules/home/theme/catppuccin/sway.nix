{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.theme.catppuccin;
in
{
  config = lib.mkIf cfg.enable {
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
  };
}
