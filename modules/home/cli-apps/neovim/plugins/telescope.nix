{ pkgs, ... }: {
  home.packages = with pkgs; [
    ripgrep
  ];

  programs.nixvim = {
    plugins.telescope = {
      enable = true;

      keymaps = {
        "<leader>f'" = { action = "marks"; desc = "View marks"; };
        "<leader>f/" = { action = "current_buffer_fuzzy_find"; desc = "Fuzzy find in current buffer"; };
        "<leader>fC" = { action = "commands"; desc = "View commands"; };
        "<leader>fb" = { action = "buffers"; desc = "View buffers"; };
        "<leader>fc" = { action = "grep_string"; desc = "Grep string"; };
        "<leader>fd" = { action = "diagnostics"; desc = "View diagnostics"; };
        "<leader>ff" = { action = "find_files"; desc = "Find files"; };
        "<leader>gC" = { action = "git_bcommits"; desc = "View git bcommits"; };
        "<leader>gb" = { action = "git_branches"; desc = "View git branches"; };
        "<leader>gc" = { action = "git_commits"; desc = "View git commits"; };
        "<leader>gt" = { action = "git_status"; desc = "View git status"; };
        "<leader>fh" = { action = "help_tags"; desc = "View help tags"; };
        "<leader>fk" = { action = "keymaps"; desc = "View keymaps"; };
        "<leader>fm" = { action = "man_pages"; desc = "View man pages"; };
        "<leader>fo" = { action = "oldfiles"; desc = "View old files"; };
        "<leader>fr" = { action = "registers"; desc = "View registers"; };
        "<leader>f<CR>" = { action = "resume"; desc = "Resume action"; };
        "<leader>fw" = { action = "live_grep"; desc = "Live grep"; };

        # TODO: map these
        # "<leader>fa" = { action = "find_files prompt_title=Config Files cwd=${vim.fn.stdpath('config')} follow=true"; desc = ""; };
        # "<leader>fF" = { action = "find_files hidden=true no_ignore=true"; desc = ""; };
        # "<leader>fn" = { action = "notify.notify"; desc = ""; };
        # "<leader>ft" = { action = "colorscheme enable_preview=true"; desc = ""; };
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
