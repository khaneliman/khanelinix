let
  catppuccin = import ../colors.nix;
in
{
  mgr = {
    cwd = {
      fg = catppuccin.colors.text.hex;
    };
    border_symbol = "│";
    border_style = {
      fg = catppuccin.colors.blue.hex;
    };
    count_copied = {
      fg = catppuccin.colors.base.hex;
      bg = catppuccin.colors.yellow.hex;
    };
    count_cut = {
      fg = catppuccin.colors.base.hex;
      bg = catppuccin.colors.pink.hex;
    };
    count_selected = {
      fg = catppuccin.colors.base.hex;
      bg = catppuccin.colors.green.hex;
    };
  };

  tabs = {
    active = {
      fg = catppuccin.colors.base.hex;
      bg = catppuccin.colors.blue.hex;
    };
    inactive = {
      fg = catppuccin.colors.text.hex;
      bg = catppuccin.colors.surface1.hex;
    };
  };
}
