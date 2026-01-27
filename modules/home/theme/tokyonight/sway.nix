{
  config,
  lib,
  ...
}:
let
  cfg = config.khanelinix.theme.tokyonight;

  tokyonight = import ./colors.nix;
  colors = tokyonight.getVariant cfg.variant;
in
{
  config = lib.mkIf cfg.enable {
    wayland.windowManager.sway = {
      config.colors = {
        background = colors.bg;

        focused = {
          childBorder = colors.blue;
          background = colors.bg;
          text = colors.fg;
          indicator = colors.cyan;
          border = colors.blue;
        };

        focusedInactive = {
          childBorder = colors.dark3;
          background = colors.bg;
          text = colors.fg;
          indicator = colors.cyan;
          border = colors.dark3;
        };

        unfocused = {
          childBorder = colors.dark3;
          background = colors.bg;
          text = colors.fg;
          indicator = colors.cyan;
          border = colors.dark3;
        };

        urgent = {
          childBorder = colors.orange;
          background = colors.bg;
          text = colors.orange;
          indicator = colors.dark3;
          border = colors.orange;
        };

        placeholder = {
          childBorder = colors.dark3;
          background = colors.bg;
          text = colors.fg;
          indicator = colors.dark3;
          border = colors.dark3;
        };
      };
    };
  };
}
