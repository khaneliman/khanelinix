_: {
  programs.nixvim = {
    plugins = {
      gitsigns = {
        enable = true;

        settings = {
          current_line_blame = true;
          current_line_blame_opts = {
            virt_text = true;
            virt_text_pos = "eol";
          };
          signs = {
            add.text = "+";
            change.text = "~";
          };
        };
      };
    };

    keymaps = [
      {
        mode = "n";
        key = "<leader>gB";
        action = ":Gitsigns blame_line<CR>";
        options = {
          desc = "Toggle Git Blame";
          silent = true;
        };
      }
    ];
  };
}
