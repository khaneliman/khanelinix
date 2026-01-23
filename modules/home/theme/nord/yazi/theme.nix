{ palette }:
let
  nord = { inherit palette; };
in
{
  mode = {
    normal_main = {
      fg = nord.palette.nord0.hex;
      bg = nord.palette.nord9.hex;
      bold = true;
    };
    normal_alt = {
      fg = nord.palette.nord9.hex;
      bg = nord.palette.nord1.hex;
    };
    select_main = {
      fg = nord.palette.nord0.hex;
      bg = nord.palette.nord14.hex;
      bold = true;
    };
    select_alt = {
      fg = nord.palette.nord14.hex;
      bg = nord.palette.nord1.hex;
    };
    unset_main = {
      fg = nord.palette.nord0.hex;
      bg = nord.palette.nord11.hex;
      bold = true;
    };
    unset_alt = {
      fg = nord.palette.nord11.hex;
      bg = nord.palette.nord1.hex;
    };
  };

  input = {
    border = {
      fg = nord.palette.nord9.hex;
    };
    title = { };
    value = { };
    selected = {
      reversed = true;
    };
  };

  pick = {
    border = {
      fg = nord.palette.nord9.hex;
    };
    active = {
      fg = nord.palette.nord15.hex;
    };
    inactive = { };
  };

  tasks = {
    border = {
      fg = nord.palette.nord9.hex;
    };
    title = { };
    hovered = {
      underline = true;
    };
  };

  which = {
    mask = {
      bg = nord.palette.nord1.hex;
    };
    cand = {
      fg = nord.palette.nord7.hex;
    };
    rest = {
      fg = nord.palette.nord3.hex;
    };
    desc = {
      fg = nord.palette.nord15.hex;
    };
    separator = "  ";
    separator_style = {
      fg = nord.palette.nord2.hex;
    };
  };

  help = {
    on = {
      fg = nord.palette.nord15.hex;
    };
    exec = {
      fg = nord.palette.nord7.hex;
    };
    desc = {
      fg = nord.palette.nord3.hex;
    };
    hovered = {
      bg = nord.palette.nord2.hex;
      bold = true;
    };
    footer = {
      fg = nord.palette.nord4.hex;
      bg = nord.palette.nord1.hex;
    };
  };
}
