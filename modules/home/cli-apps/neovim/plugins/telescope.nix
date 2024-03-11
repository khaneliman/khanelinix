{ pkgs, ... }: {
  home.packages = with pkgs; [
    ripgrep
  ];

  programs.nixvim = {

    keymaps = [
      {
        mode = "n";
        key = "<leader>fc";
        lua = true;
        action = /*lua*/ ''
          function()
            require("telescope.builtin").find_files {
              prompt_title = "Config Files",
              cwd = vim.fn.stdpath "config",
              follow = true,
            }
          end
        '';
        options = {
          desc = "Find config files";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>fF";
        lua = true;
        action = /*lua*/ ''
          function()
            require("telescope.builtin").find_files({ hidden = true, no_ignore = true})
          end
        '';
        options = {
          desc = "Find all files";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>fn";
        lua = true;
        action = /*lua*/ ''
          function()
            require("telescope").extensions.notify.notify()
          end
        '';
        options = {
          desc = "Find notifications";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>ft";
        lua = true;
        action = /*lua*/ ''
          function()
            require("telescope.builtin").colorscheme({ enable_preview = true })
          end
        '';
        options = {
          desc = "Find theme";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>fW";
        lua = true;
        action = /*lua*/ ''
          function()
            require("telescope.builtin").live_grep {
              additional_args = function(args) return vim.list_extend(args, { "--hidden", "--no-ignore" }) end,
            }
          end
        '';
        options = {
          desc = "Find words in all files";
          silent = true;
        };
      }
    ];

    plugins.project-nvim.enable = true;

    plugins.telescope = {
      enable = true;

      extensions = {
        file_browser = {
          enable = true;
          hidden = true;
        };

        frecency = {
          enable = true;
        };

        project-nvim = {
          enable = true;
        };

        ui-select = {
          enable = true;
        };
      };

      keymaps = {
        "<leader>f'" = { action = "marks"; desc = "View marks"; };
        "<leader>f/" = { action = "current_buffer_fuzzy_find"; desc = "Fuzzy find in current buffer"; };
        "<leader>f<CR>" = { action = "resume"; desc = "Resume action"; };
        "<leader>fC" = { action = "commands"; desc = "View commands"; };
        "<leader>fb" = { action = "buffers"; desc = "View buffers"; };
        "<leader>fc" = { action = "grep_string"; desc = "Grep string"; };
        "<leader>fd" = { action = "diagnostics"; desc = "View diagnostics"; };
        "<leader>ff" = { action = "find_files"; desc = "Find files"; };
        "<leader>fh" = { action = "help_tags"; desc = "View help tags"; };
        "<leader>fk" = { action = "keymaps"; desc = "View keymaps"; };
        "<leader>fm" = { action = "man_pages"; desc = "View man pages"; };
        "<leader>fo" = { action = "oldfiles"; desc = "View old files"; };
        "<leader>fr" = { action = "registers"; desc = "View registers"; };
        "<leader>fs" = { action = "lsp_document_symbols"; desc = "Search symbols"; };
        "<leader>fw" = { action = "live_grep"; desc = "Live grep"; };
        "<leader>gC" = { action = "git_bcommits"; desc = "View git bcommits"; };
        "<leader>gb" = { action = "git_branches"; desc = "View git branches"; };
        "<leader>gc" = { action = "git_commits"; desc = "View git commits"; };
        "<leader>gt" = { action = "git_status"; desc = "View git status"; };
      };

      keymapsSilent = true;

      defaults = {
        file_ignore_patterns = [
          "^.git/"
          "^.mypy_cache/"
          "^__pycache__/"
          "^output/"
          "^data/"
          "%.ipynb"
        ];
        set_env.COLORTERM = "truecolor";
      };
    };
  };
}
