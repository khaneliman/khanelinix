_: {
  programs.nixvim = {
    plugins.mini = {
      enable = true;

      modules = {
        basics = { };
        bracketed = { };
        bufremove = { };
        indentscope = { };

        map = {
          # __raw = lua code
          # __unkeyed.* = no key, just the value
          integrations = {
            "__unkeyed.builtin_search".__raw = # lua
              "require('mini.map').gen_integration.builtin_search()";
            "__unkeyed.gitsigns".__raw = # lua
              "require('mini.map').gen_integration.gitsigns()";
            "__unkeyed.diagnostic".__raw = # lua
              "require('mini.map').gen_integration.diagnostic()";
          };

          window = {
            winblend = 0;
          };
        };

        starter = {
          header = ''
            ██╗  ██╗██╗  ██╗ █████╗ ███╗   ██╗███████╗██╗     ██╗███╗   ██╗██╗██╗  ██╗
            ██║ ██╔╝██║  ██║██╔══██╗████╗  ██║██╔════╝██║     ██║████╗  ██║██║╚██╗██╔╝
            █████╔╝ ███████║███████║██╔██╗ ██║█████╗  ██║     ██║██╔██╗ ██║██║ ╚███╔╝
            ██╔═██╗ ██╔══██║██╔══██║██║╚██╗██║██╔══╝  ██║     ██║██║╚██╗██║██║ ██╔██╗
            ██║  ██╗██║  ██║██║  ██║██║ ╚████║███████╗███████╗██║██║ ╚████║██║██╔╝ ██╗
            ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝╚══════╝╚═╝╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝
          '';

          evaluate_single = true;

          items = {
            "__unkeyed.buildtin_actions".__raw = "require('mini.starter').sections.builtin_actions()";
            "__unkeyed.recent_files_current_directory".__raw = "require('mini.starter').sections.recent_files(10, false)";
            "__unkeyed.recent_files".__raw = "require('mini.starter').sections.recent_files(10, true)";
            "__unkeyed.sessions".__raw = "require('mini.starter').sections.sessions(5, true)";
          };

          content_hooks = {
            "__unkeyed.adding_bullet".__raw = "require('mini.starter').gen_hook.adding_bullet()";
            "__unkeyed.indexing".__raw = "require('mini.starter').gen_hook.indexing('all', { 'Builtin actions' })";
            "__unkeyed.padding".__raw = "require('mini.starter').gen_hook.aligning('center', 'center')";
          };
        };

        surround = { };
      };
    };

    keymaps = [
      {
        mode = "n";
        key = "<leader>um";
        lua = true;
        action = # lua
          "MiniMap.toggle";
        options = {
          desc = "Toggle MiniMap";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>c";
        lua = true;
        action = # lua
          ''require("mini.bufremove").delete'';
        options = {
          desc = "Close buffer";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<C-w>";
        lua = true;
        action = # lua
          ''require("mini.bufremove").delete'';
        options = {
          desc = "Close buffer";
          silent = true;
        };
      }
      {
        key = "<leader>bc";
        action = # lua
          ''
            function ()
              local current = vim.api.nvim_get_current_buf()

              local get_listed_bufs = function()
                return vim.tbl_filter(function(bufnr)
                 return vim.api.nvim_buf_get_option(bufnr, "buflisted")
                end, vim.api.nvim_list_bufs())
              end

              for _, bufnr in ipairs(get_listed_bufs()) do
                if bufnr ~= current
                then require("mini.bufremove").delete(bufnr)
                end
              end
            end
          '';
        lua = true;
        options = {
          desc = "Close all buffers but current";
        };
      }
    ];
  };
}
