_:
let
  catppuccin = import ../colors.nix;
in
{
  status = {
    # FIXME:
    # sep_left = {
    #   open = "󰅂";
    #   close = "󰅂";
    # };
    #
    # FIXME:
    # sep_right = {
    #   open = "󰅁";
    #   close = "󰅁";
    # };

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

    overall = {
      fg = catppuccin.colors.text.hex;
      bg = catppuccin.colors.mantle.hex;
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

    perm_type = {
      fg = catppuccin.colors.blue.hex;
    };
    perm_read = {
      fg = catppuccin.colors.yellow.hex;
    };
    perm_write = {
      fg = catppuccin.colors.red.hex;
    };
    perm_exec = {
      fg = catppuccin.colors.green.hex;
    };
    perm_sep = {
      fg = catppuccin.colors.overlay1.hex;
    };
  };
}
