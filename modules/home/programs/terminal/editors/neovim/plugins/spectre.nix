_: {
  programs.nixvim = {
    plugins = {
      spectre = {
        enable = true;
      };
    };

    keymaps = [
      {
        mode = "n";
        key = "<leader>rs";
        action = ":Spectre<CR>";
        options = {
          desc = "Toggle Spectre";
          silent = true;
        };
      }
    ];
  };
}
