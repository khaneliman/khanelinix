_:
let
  catppuccin = import ../colors.nix;
in
{
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

  select = {
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

  which = {
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
    on = {
      fg = catppuccin.colors.pink.hex;
    };
    exec = {
      fg = catppuccin.colors.teal.hex;
    };
    desc = {
      fg = catppuccin.colors.overlay2.hex;
    };
    hovered = {
      bg = catppuccin.colors.surface2.hex;
      bold = true;
    };
    footer = {
      fg = catppuccin.colors.surface1.hex;
      bg = catppuccin.colors.text.hex;
    };
  };
}
