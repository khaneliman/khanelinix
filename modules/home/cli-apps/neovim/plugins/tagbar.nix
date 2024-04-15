_: {
  programs.nixvim = {
    plugins.tagbar = {
      enable = true;
      settings.width = 50;
    };

    keymaps = [
      {
        mode = "n";
        key = "<leader>ut";
        action = ":TagbarToggle<cr>";
        options = {
          desc = "Toggle Tagbar";
          silent = true;
        };
      }
    ];
  };
}
