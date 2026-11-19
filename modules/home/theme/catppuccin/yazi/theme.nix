{ colors }:
{
  mode = {
    normal_main = {
      fg = colors.base.hex;
      bg = colors.blue.hex;
      bold = true;
    };
    normal_alt = {
      fg = colors.blue.hex;
      bg = colors.surface0.hex;
    };
    select_main = {
      fg = colors.base.hex;
      bg = colors.green.hex;
      bold = true;
    };
    select_alt = {
      fg = colors.green.hex;
      bg = colors.surface0.hex;
    };
    unset_main = {
      fg = colors.base.hex;
      bg = colors.maroon.hex;
      bold = true;
    };
    unset_alt = {
      fg = colors.maroon.hex;
      bg = colors.surface0.hex;
    };
  };

  input = {
    border = {
      fg = colors.blue.hex;
    };
    title = { };
    value = { };
    selected = {
      reversed = true;
    };
  };

  pick = {
    border = {
      fg = colors.blue.hex;
    };
    active = {
      fg = colors.pink.hex;
    };
    inactive = { };
  };

  tasks = {
    border = {
      fg = colors.blue.hex;
    };
    title = { };
    hovered = {
      underline = true;
    };
  };

  confirm = {
    border = {
      fg = colors.blue.hex;
    };
    title = {
      fg = colors.blue.hex;
    };
    body = { };
    list = { };
    btn_yes = {
      reversed = true;
    };
    btn_no = { };
  };

  which = {
    border = {
      fg = colors.blue.hex;
    };
    mask = {
      bg = colors.surface0.hex;
    };
    cand = {
      fg = colors.teal.hex;
    };
    rest = {
      fg = colors.overlay2.hex;
    };
    desc = {
      fg = colors.pink.hex;
    };
    separator = "  ";
    separator_style = {
      fg = colors.surface2.hex;
    };
  };

  help = {
    border = {
      fg = colors.blue.hex;
    };
    chord = {
      fg = colors.pink.hex;
    };
    action = {
      fg = colors.teal.hex;
    };
    hovered = {
      reversed = true;
      bold = true;
    };
  };
}
