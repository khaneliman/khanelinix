_: {
  programs.nixvim = {
    plugins = {
      mini = {
        enable = true;

        modules = {
          fuzzy = { };
        };
      };

      telescope = {
        settings = {
          defaults = {
            file_sorter.__raw = # Lua
              ''require('mini.fuzzy').get_telescope_sorter'';
            generic_sorter.__raw = # Lua
              ''require('mini.fuzzy').get_telescope_sorter'';
          };
        };
      };
    };
  };
}
