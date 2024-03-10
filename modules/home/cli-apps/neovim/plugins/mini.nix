_: {
  programs.nixvim = {
    plugins.mini = {
      enable = true;

      modules = {
        basics = { };
        bracketed = { };
        indentscope = { };
        map = {
          # __raw = lua code
          # __unkeyed.* = no key, just the value
          integrations = {
            "__unkeyed.builtin_search".__raw = "require('mini.map').gen_integration.builtin_search()";
            "__unkeyed.gitsigns".__raw = "require('mini.map').gen_integration.gitsigns()";
            "__unkeyed.diagnostic".__raw = "require('mini.map').gen_integration.diagnostic()";
          };

          window = {
            winblend = 0;
          };
        };
        surround = { };
      };
    };

    keymaps = [
      {
        mode = "n";
        key = "<leader>mt";
        lua = true;
        action = "MiniMap.toggle";
        options = {
          desc = "Toggle MiniMap";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>mf";
        lua = true;
        action = "MiniMap.toggle_focus";
        options = {
          desc = "Focus MiniMap";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>mr";
        lua = true;
        action = "MiniMap.refresh";
        options = {
          desc = "Refresh MiniMap";
          silent = true;
        };
      }
    ];
  };
}
