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
        key = "<leader>gb";
        action = ":Gitsigns blame_line<CR>";
        options = {
          desc = "Toggle Git Blame";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>gu";
        action = "<cmd>Gitsigns undo_stage_hunk<CR>";
        options = {
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>g<C-w>";
        action = "<cmd>Gitsigns preview_hunk<CR>";
        options = {
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>gp";
        action = "<cmd>Gitsigns prev_hunk<CR>";
        options = {
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>gn";
        action = "<cmd>Gitsigns next_hunk<CR>";
        options = {
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>gP";
        action = "<cmd>Gitsigns preview_hunk_inline<CR>";
        options = {
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>gR";
        action = "<cmd>Gitsigns reset_buffer<CR>";
        options = {
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>gD";
        action = "<cmd>Gitsigns diffthis HEAD<CR>";
        options = {
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>gw";
        action = "<cmd>Gitsigns toggle_word_diff<CR>";
        options = {
          silent = true;
        };
      }
    ];
  };
}
