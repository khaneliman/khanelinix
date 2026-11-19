{ colors }:
{
  mgr = {
    cwd = {
      fg = colors.text.hex;
    };
    border_symbol = "│";
    border_style = {
      fg = colors.blue.hex;
    };
    count_copied = {
      fg = colors.base.hex;
      bg = colors.yellow.hex;
    };
    count_cut = {
      fg = colors.base.hex;
      bg = colors.pink.hex;
    };
    count_selected = {
      fg = colors.base.hex;
      bg = colors.green.hex;
    };
  };

  tabs = {
    active = {
      fg = colors.base.hex;
      bg = colors.blue.hex;
    };
    inactive = {
      fg = colors.text.hex;
      bg = colors.surface1.hex;
    };
  };
}
