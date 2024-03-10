_: {
  programs.nixvim.autoCmd = [
    # Vertically center document when entering insert mode
    {
      event = "InsertEnter";
      command = "norm zz";
    }

    # Remove trailing whitespace on save
    {
      event = "BufWrite";
      command = "%s/\\s\\+$//e";
    }

    # Refresh minimap on save
    # {
    #   event = "BufWrite";
    #   callback = { __raw = "MiniMap.refresh"; };
    # }

    # Open minimap on buffers
    {
      event = "BufRead";
      once = true;
      callback = { __raw = "MiniMap.open"; };
    }

    # Open Neo-Tree on buffer
    # FIX: shouldn't focus but is...
    {
      event = "BufReadPost";
      once = true;
      command = "Neotree show filesystem left";
      # callback = {
      #   __raw =
      #     "function() vim.api.nvim_exec('Neotree show filesystem left', true) end";
      # };
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
