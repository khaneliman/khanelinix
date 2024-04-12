{ config, lib }:
let
  catppuccin = import ../../desktop/theme/catppuccin.nix;
in
{
  manager = {
    cwd = {
      fg = catppuccin.colors.text.hex;
    };
    hovered = {
      fg = catppuccin.colors.base.hex;
      bg = catppuccin.colors.blue.hex;
    };
    preview_hovered = {
      underline = true;
    };
    find_keyword = {
      fg = catppuccin.colors.yellow.hex;
      italic = true;
    };
    find_position = {
      fg = catppuccin.colors.pink.hex;
      bg = "reset";
      italic = true;
    };
    marker_selected = {
      fg = catppuccin.colors.green.hex;
      bg = catppuccin.colors.green.hex;
    };
    marker_copied = {
      fg = catppuccin.colors.yellow.hex;
      bg = catppuccin.colors.yellow.hex;
    };
    marker_cut = {
      fg = catppuccin.colors.red.hex;
      bg = catppuccin.colors.red.hex;
    };
    tab_active = {
      fg = catppuccin.colors.base.hex;
      bg = catppuccin.colors.blue.hex;
    };
    tab_inactive = {
      fg = catppuccin.colors.text.hex;
      bg = catppuccin.colors.surface1.hex;
    };
    tab_width = 1;
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
    syntect_theme =
      let
        cfg = config.khanelinix.desktop.theme;
        inherit (lib.internal) capitalize;
      in
      "/bat/${capitalize cfg.selectedTheme.name} ${capitalize cfg.selectedTheme.variant}.tmTheme";
  };

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

  filetype = {
    rules = [
      {
        mime = "image/*";
        fg = catppuccin.colors.teal.hex;
      }
      {
        mime = "video/*";
        fg = catppuccin.colors.yellow.hex;
      }
      {
        mime = "audio/*";
        fg = catppuccin.colors.yellow.hex;
      }
      {
        mime = "application/zip";
        fg = catppuccin.colors.pink.hex;
      }
      {
        mime = "application/gzip";
        fg = catppuccin.colors.pink.hex;
      }
      {
        mime = "application/x-tar";
        fg = catppuccin.colors.pink.hex;
      }
      {
        mime = "application/x-bzip";
        fg = catppuccin.colors.pink.hex;
      }
      {
        mime = "application/x-bzip2";
        fg = catppuccin.colors.pink.hex;
      }
      {
        mime = "application/x-7z-compressed";
        fg = catppuccin.colors.pink.hex;
      }
      {
        mime = "application/x-rar";
        fg = catppuccin.colors.pink.hex;
      }
      {
        name = "*";
        fg = catppuccin.colors.text.hex;
      }
      {
        name = "*/";
        fg = catppuccin.colors.blue.hex;
      }
    ];
  };
}
