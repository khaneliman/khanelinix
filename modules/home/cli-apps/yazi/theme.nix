{ config, lib }:
{
  manager = {
    cwd = {
      fg = "#cad3f5";
    };
    hovered = {
      fg = "#24273a";
      bg = "#8aadf4";
    };
    preview_hovered = {
      underline = true;
    };
    find_keyword = {
      fg = "#eed49f";
      italic = true;
    };
    find_position = {
      fg = "#f5bde6";
      bg = "reset";
      italic = true;
    };
    marker_selected = {
      fg = "#a6da95";
      bg = "#a6da95";
    };
    marker_copied = {
      fg = "#eed49f";
      bg = "#eed49f";
    };
    marker_cut = {
      fg = "#ed8796";
      bg = "#ed8796";
    };
    tab_active = {
      fg = "#24273a";
      bg = "#8aadf4";
    };
    tab_inactive = {
      fg = "#cad3f5";
      bg = "#494d64";
    };
    tab_width = 1;
    border_symbol = "│";
    border_style = {
      fg = "#8aadf4";
    };
    count_copied = {
      fg = "#24273a";
      bg = "#eed49f";
    };
    count_cut = {
      fg = "#24273a";
      bg = "#f5bde6";
    };
    count_selected = {
      fg = "#24273a";
      bg = "#a6da95";
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
      fg = "#494d64";
      bg = "#494d64";
    };

    mode_normal = {
      fg = "#24273a";
      bg = "#8aadf4";
      bold = true;
    };
    mode_select = {
      fg = "#24273a";
      bg = "#a6da95";
      bold = true;
    };
    mode_unset = {
      fg = "#24273a";
      bg = "#f0c6c6";
      bold = true;
    };

    progress_label = {
      fg = "#ffffff";
      bold = true;
    };
    progress_normal = {
      fg = "#8aadf4";
      bg = "#494d64";
    };
    progress_error = {
      fg = "#ed8796";
      bg = "#494d64";
    };

    permissions_t = {
      fg = "#8aadf4";
    };
    permissions_r = {
      fg = "#eed49f";
    };
    permissions_w = {
      fg = "#ed8796";
    };
    permissions_x = {
      fg = "#a6da95";
    };
    permissions_s = {
      fg = "#8087a2";
    };
  };

  input = {
    border = {
      fg = "#8aadf4";
    };
    title = { };
    value = { };
    selected = {
      reversed = true;
    };
  };

  select = {
    border = {
      fg = "#8aadf4";
    };
    active = {
      fg = "#f5bde6";
    };
    inactive = { };
  };

  tasks = {
    border = {
      fg = "#8aadf4";
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
      fg = "#8bd5ca";
    };
    rest = {
      fg = "#939ab7";
    };
    desc = {
      fg = "#f5bde6";
    };
    separator = "  ";
    separator_style = {
      fg = "#5b6078";
    };
  };

  help = {
    on = {
      fg = "#f5bde6";
    };
    exec = {
      fg = "#8bd5ca";
    };
    desc = {
      fg = "#939ab7";
    };
    hovered = {
      bg = "#5b6078";
      bold = true;
    };
    footer = {
      fg = "#494d64";
      bg = "#cad3f5";
    };
  };

  filetype = {
    rules = [
      {
        mime = "image/*";
        fg = "#8bd5ca";
      }
      {
        mime = "video/*";
        fg = "#eed49f";
      }
      {
        mime = "audio/*";
        fg = "#eed49f";
      }
      {
        mime = "application/zip";
        fg = "#f5bde6";
      }
      {
        mime = "application/gzip";
        fg = "#f5bde6";
      }
      {
        mime = "application/x-tar";
        fg = "#f5bde6";
      }
      {
        mime = "application/x-bzip";
        fg = "#f5bde6";
      }
      {
        mime = "application/x-bzip2";
        fg = "#f5bde6";
      }
      {
        mime = "application/x-7z-compressed";
        fg = "#f5bde6";
      }
      {
        mime = "application/x-rar";
        fg = "#f5bde6";
      }
      {
        name = "*";
        fg = "#cad3f5";
      }
      {
        name = "*/";
        fg = "#8aadf4";
      }
    ];
  };
}
