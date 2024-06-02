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

      which-key.registrations."<leader>"."g" = {
        "h" = mkIf config.programs.nixvim.plugins.gitsigns.enable { name = "  Hunks"; };
        "t" = mkIf config.programs.nixvim.plugins.gitsigns.enable { name = "  Toggle"; };
      };
    };

    keymaps = [
      {
        mode = "n";
        key = "<leader>gtb";
        action = ":Gitsigns toggle_current_line_blame<CR>";
        options = {
          desc = "Toggle Git Blame";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>gtd";
        action = ":Gitsigns toggle_deleted<CR>";
        options = {
          desc = "Toggle Deleted";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>gtl";
        action = ":Gitsigns toggle_linehl<CR>";
        options = {
          desc = "Toggle Line Highlight";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>gtn";
        action = ":Gitsigns toggle_numhl<CR>";
        options = {
          desc = "Toggle Number Highlight";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>gtw";
        action = "<cmd>Gitsigns toggle_word_diff<CR>";
        options = {
          desc = "Toggle Word Diff";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>gts";
        action = "<cmd>Gitsigns toggle_signs<CR>";
        options = {
          desc = "Toggle Signs";
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
          desc = "Git Blame";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>ghp";
        action.__raw = ''
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
        action.__raw = ''
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
