{ ... }: {
  programs.nixvim = {
    plugins.telescope = {
      enable = true;

      keymaps = {
        "<leader>gb" = { action = "git_branches"; desc = ""; };
        "<leader>gc" = { action = "git_commits"; desc = ""; };
        "<leader>gC" = { action = "git_bcommits"; desc = ""; };
        "<leader>gt" = { action = "git_status"; desc = ""; };
        "<leader>f<CR>" = { action = "resume"; desc = ""; };
        "<leader>f'" = { action = "marks"; desc = ""; };
        "<leader>f/" = { action = "current_buffer_fuzzy_find"; desc = ""; };
        # "<leader>fa" = { action = "find_files prompt_title=Config Files cwd=${vim.fn.stdpath('config')} follow=true"; desc = ""; };
        "<leader>fb" = { action = "buffers"; desc = ""; };
        "<leader>fc" = { action = "grep_string"; desc = ""; };
        "<leader>fC" = { action = "commands"; desc = ""; };
        "<leader>fd" = { action = "diagnostics"; desc = ""; };
        "<leader>ff" = { action = "find_files"; desc = ""; };
        # "<leader>fF" = { action = "find_files hidden=true no_ignore=true"; desc = ""; };
        # "<leader>fg" = { action = "live_grep"; desc = ""; };
        "<leader>fh" = { action = "help_tags"; desc = ""; };
        "<leader>fk" = { action = "keymaps"; desc = ""; };
        "<leader>fm" = { action = "man_pages"; desc = ""; };
        # "<leader>fn" = { action = "notify.notify"; desc = ""; };
        "<leader>fo" = { action = "oldfiles"; desc = ""; };
        "<leader>fr" = { action = "registers"; desc = ""; };
        # "<leader>ft" = { action = "colorscheme enable_preview=true"; desc = ""; };
        "<leader>fw" = { action = "live_grep"; desc = ""; };
        # "<leader>fW" = { action = "live_grep { additional_args = function(args) return vim.list_extend(args, { \"--hidden\", \"--no-ignore\" }) end,}"; desc = ""; };
        # "<leader>ls" = { action = "aerial.aerial"; desc = ""; };
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
