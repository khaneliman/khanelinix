_:
let
  catppuccin = import ../colors.nix;
in
{
  status = {
    separator_open = "";
    separator_close = "";
    separator_style = {
      fg = catppuccin.colors.surface1.hex;
      bg = catppuccin.colors.surface1.hex;
    };

    mode_normal = {
      fg = catppuccin.colors.base.hex;
      bg = catppuccin.colors.blue.hex;
      bold = true;
    };
    mode_select = {
      fg = catppuccin.colors.base.hex;
      bg = catppuccin.colors.green.hex;
      bold = true;
    };
    mode_unset = {
      fg = catppuccin.colors.base.hex;
      bg = catppuccin.colors.flamingo.hex;
      bold = true;
    };

    progress_label = {
      fg = "#ffffff";
      bold = true;
    };
    progress_normal = {
      fg = catppuccin.colors.blue.hex;
      bg = catppuccin.colors.surface1.hex;
    };
    progress_error = {
      fg = catppuccin.colors.red.hex;
      bg = catppuccin.colors.surface1.hex;
    };

    permissions_t = {
      fg = catppuccin.colors.blue.hex;
    };
    permissions_r = {
      fg = catppuccin.colors.yellow.hex;
    };
    permissions_w = {
      fg = catppuccin.colors.red.hex;
    };
    permissions_x = {
      fg = catppuccin.colors.green.hex;
    };
    permissions_s = {
      fg = catppuccin.colors.overlay1.hex;
    };
  };
}
