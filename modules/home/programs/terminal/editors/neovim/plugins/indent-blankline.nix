{ config, lib, ... }:
{
  programs.nixvim = {
    plugins = {
      indent-blankline = {
        enable = true;

        settings = {
          scope.enabled = false;
        };
      };
    };

    keymaps = lib.optionals config.programs.nixvim.plugins.indent-blankline.enable [
      {
        mode = "n";
        key = "<leader>ui";
        action = ":IBLToggle<CR>";
        options = {
          desc = "Indent-Blankline toggle";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>uI";
        action = ":IBLToggleScope<CR>";
        options = {
          desc = "Indent-Blankline Scope toggle";
          silent = true;
        };
      }
    ];
  };
}
