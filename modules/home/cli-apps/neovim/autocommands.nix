_: {
  programs.nixvim.autoCmd = [
    # Remove trailing whitespace on save
    {
      event = "BufWrite";
      command = "%s/\\s\\+$//e";
    }

    # Open minimap on first buffer
    {
      event = "BufRead";
      once = true;
      callback = { __raw = "MiniMap.open"; };
    }

    # Open Neo-Tree on first buffer
    {
      event = "BufWinEnter";
      callback = {
        __raw = ''
          function(table)
            if vim.api.nvim_buf_get_name(0) ~= "" and not vim.g.first_buffer_opened then
              vim.g.first_buffer_opened = true
              vim.api.nvim_exec('Neotree show filesystem left', true)
            end
          end
        '';
      };
    }

    # Enable spellcheck for some filetypes
    {
      event = "FileType";
      pattern = [
        "tex"
        "latex"
        "markdown"
      ];
      command = "setlocal spell spelllang=en_us";
    }
  ];
}
