{ config, lib, ... }:
let
  inherit (builtins) toJSON;
  inherit (lib) mkIf;
in
{
  programs.nixvim = {
    plugins = {
      gitsigns = {
        enable = true;

        settings = {
          current_line_blame = true;

          current_line_blame_opts = {
            delay = 500;

            ignore_blank_lines = true;
            ignore_whitespace = true;
            virt_text = true;
            virt_text_pos = "eol";
          };

          signcolumn = false;
        };
      };

      which-key.registrations."<leader>" = {
        "g" = {
          "h" = mkIf config.programs.nixvim.plugins.gitsigns.enable { name = "  Hunks"; };
        };
        "u" = {
          "g" = mkIf config.programs.nixvim.plugins.gitsigns.enable { name = "󰊢 Git"; };
        };
      };
    };

    keymaps = [
      # UI binds
      {
        mode = "n";
        key = "<leader>ugb";
        action = ":Gitsigns toggle_current_line_blame<CR>";
        options = {
          desc = "Git Blame toggle";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>ugd";
        action = ":Gitsigns toggle_deleted<CR>";
        options = {
          desc = "Deleted toggle";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>ugl";
        action = ":Gitsigns toggle_linehl<CR>";
        options = {
          desc = "Line Highlight toggle";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>ugh";
        action = ":Gitsigns toggle_numhl<CR>";
        options = {
          desc = "Number Highlight toggle";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>ugw";
        action = "<cmd>Gitsigns toggle_word_diff<CR>";
        options = {
          desc = "Word Diff toggle";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>ugs";
        action = "<cmd>Gitsigns toggle_signs<CR>";
        options = {
          desc = "Signs toggle";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>gb";
        action.__raw = # Lua
          ''
            function() require("gitsigns").blame_line{full=true} end
          '';
        options = {
          desc = "Git Blame toggle";
          silent = true;
        };
      }
      # Hunk binds
      {
        mode = "n";
        key = "<leader>ghp";
        action.__raw = # Lua
          ''
            function()
              if vim.wo.diff then return ${toJSON "<leader>gp"} end

              vim.schedule(function() require("gitsigns").prev_hunk() end)

              return '<Ignore>'
            end
          '';
        options = {
          desc = "Previous hunk";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>ghn";
        action.__raw = # Lua
          ''
            function()
              if vim.wo.diff then return ${toJSON "<leader>gn"} end

              vim.schedule(function() require("gitsigns").next_hunk() end)

              return '<Ignore>'
            end
          '';
        options = {
          desc = "Next hunk";
          silent = true;
        };
      }
      {
        mode = [
          "n"
          "v"
        ];
        key = "<leader>ghs";
        action = "<cmd>Gitsigns stage_hunk<CR>";
        options = {
          desc = "Stage hunk";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>ghu";
        action = "<cmd>Gitsigns undo_stage_hunk<CR>";
        options = {
          desc = "Undo stage hunk";
          silent = true;
        };
      }
      {
        mode = [
          "n"
          "v"
        ];
        key = "<leader>ghr";
        action = "<cmd>Gitsigns reset_hunk<CR>";
        options = {
          desc = "Reset hunk";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>ghP";
        action = "<cmd>Gitsigns preview_hunk<CR>";
        options = {
          desc = "Preview hunk";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>gh<C-p>";
        action = "<cmd>Gitsigns preview_hunk_inline<CR>";
        options = {
          desc = "Preview hunk inline";
          silent = true;
        };
      }
      # Buffer binds
      {
        mode = "n";
        key = "<leader>gS";
        action = "<cmd>Gitsigns stage_buffer<CR>";
        options = {
          desc = "Stage buffer";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>gR";
        action = "<cmd>Gitsigns reset_buffer<CR>";
        options = {
          desc = "Reset buffer";
          silent = true;
        };
      }
    ];
  };
}
