let
  catppuccin = import ../colors.nix;
in
{
  mode = {
    normal_main = {
      fg = catppuccin.colors.base.hex;
      bg = catppuccin.colors.blue.hex;
      bold = true;
    };
    normal_alt = {
      fg = catppuccin.colors.blue.hex;
      bg = catppuccin.colors.surface0.hex;
    };
    select_main = {
      fg = catppuccin.colors.base.hex;
      bg = catppuccin.colors.green.hex;
      bold = true;
    };
    select_alt = {
      fg = catppuccin.colors.green.hex;
      bg = catppuccin.colors.surface0.hex;
    };
    unset_main = {
      fg = catppuccin.colors.base.hex;
      bg = catppuccin.colors.maroon.hex;
      bold = true;
    };
    unset_alt = {
      fg = catppuccin.colors.maroon.hex;
      bg = catppuccin.colors.surface0.hex;
    };
  };

  input = {
    border = {
      fg = catppuccin.colors.blue.hex;
    };
    title = { };
    value = { };
    selected = {
      reversed = true;
    };
  };

  pick = {
    border = {
      fg = catppuccin.colors.blue.hex;
    };
    active = {
      fg = catppuccin.colors.pink.hex;
    };
    inactive = { };
  };

  tasks = {
    border = {
      fg = catppuccin.colors.blue.hex;
    };
    title = { };
    hovered = {
      underline = true;
    };
  };

  confirm = {
    border = {
      fg = catppuccin.colors.blue.hex;
    };
    title = {
      fg = catppuccin.colors.blue.hex;
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
      fg = catppuccin.colors.blue.hex;
    };
    mask = {
      bg = "#363a4f";
    };
    cand = {
      fg = catppuccin.colors.teal.hex;
    };
    rest = {
      fg = catppuccin.colors.overlay2.hex;
    };
    desc = {
      fg = catppuccin.colors.pink.hex;
    };
    separator = "  ";
    separator_style = {
      fg = catppuccin.colors.surface2.hex;
    };
  };

  help = {
    border = {
      fg = catppuccin.colors.blue.hex;
    };
    chord = {
      fg = catppuccin.colors.pink.hex;
    };
    action = {
      fg = catppuccin.colors.teal.hex;
    };
    hovered = {
      reversed = true;
      bold = true;
    };
  };
}
