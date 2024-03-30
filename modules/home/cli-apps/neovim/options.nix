_: {
  programs.nixvim = {
    globals = {
      # Disable useless providers
      loaded_ruby_provider = 0; # Ruby
      loaded_perl_provider = 0; # Perl
      loaded_python_provider = 0; # Python 2
      disable_autoformat = false;
      colorizing_enabled = 1;
      first_buffer_opened = false;
      dotnet_build_project.__raw = ''
        function()
          local default_path = vim.fn.getcwd() .. '/'

          if vim.g['dotnet_last_proj_path'] ~= nil then
              default_path = vim.g['dotnet_last_proj_path']
          end

          local path = vim.fn.input('Path to your *proj file', default_path, 'file')

          vim.g['dotnet_last_proj_path'] = path

          local cmd = 'dotnet build -c Debug ' .. path .. ' > /dev/null'

          print("")
          print('Cmd to execute: ' .. cmd)

          local f = os.execute(cmd)

          if f == 0 then
              print('\nBuild: ✔️ ')
          else
              print('\nBuild: ❌ (code: ' .. f .. ')')
          end
        end
      '';
      dotnet_get_dll_path.__raw = ''
        function()
          local request = function()
              return vim.fn.input('Path to dll', vim.fn.getcwd() .. '/bin/Debug/', 'file')
          end

          if vim.g['dotnet_last_dll_path'] == nil then
              vim.g['dotnet_last_dll_path'] = request()
          else
              if vim.fn.confirm('Do you want to change the path to dll?\n' .. vim.g['dotnet_last_dll_path'], '&yes\n&no', 2) == 1 then
                  vim.g['dotnet_last_dll_path'] = request()
              end
          end

          return vim.g['dotnet_last_dll_path']
        end
      '';
    };

    clipboard = {
      # Use system clipboard
      register = "unnamedplus";

      providers.wl-copy.enable = true;
    };

    opts = {
      updatetime = 100; # Faster completion

      # Line numbers
      relativenumber = true; # Relative line numbers
      number = true; # Display the absolute line number of the current line
      hidden = true; # Keep closed buffer open in the background
      mouse = "a"; # Enable mouse control
      mousemodel = "extend"; # Mouse right-click extends the current selection
      splitbelow = true; # A new window is put below the current one
      splitright = true; # A new window is put right of the current one

      swapfile = false; # Disable the swap file
      modeline = true; # Tags such as 'vim:ft=sh'
      modelines = 100; # Sets the type of modelines
      undofile = true; # Automatically save and restore undo history
      incsearch = true; # Incremental search: show match for partly typed search command
      ignorecase = true; # When the search query is lower-case, match both lower and upper-case
      #   patterns
      smartcase = true; # Override the 'ignorecase' option if the search pattern contains upper
      #   case characters
      cursorline = true; # Highlight the screen line of the cursor
      cursorcolumn = false; # Highlight the screen column of the cursor
      signcolumn = "yes"; # Whether to show the signcolumn
      colorcolumn = "100"; # Columns to highlight
      laststatus = 3; # When to use a status line for the last window
      fileencoding = "utf-8"; # File-content encoding for the current buffer
      termguicolors = true; # Enables 24-bit RGB color in the |TUI|
      spell = false; # Highlight spelling mistakes (local to window)
      wrap = false; # Prevent text from wrapping

      # Tab options
      tabstop = 2; # Number of spaces a <Tab> in the text stands for (local to buffer)
      shiftwidth = 2; # Number of spaces used for each step of (auto)indent (local to buffer)
      softtabstop = 0; # If non-zero, number of spaces to insert for a <Tab> (local to buffer)
      expandtab = true; # Expand <Tab> to spaces in Insert mode (local to buffer)
      autoindent = true; # Do clever autoindenting

      textwidth = 0; # Maximum width of text that is being inserted.  A longer line will be
      #   broken after white space to get this width.

      # Folding
      foldlevel = 99; # Folds with a level higher than this number will be closed
      foldcolumn = "1";
      foldenable = true;
      foldlevelstart = 99;

      # backspace = { append = [ "nostop" ]; };
      breakindent = true;
      cmdheight = 0;
      copyindent = true;
      # diffopt = { append = [ "algorithm:histogram" "linematch:60" ]; };
      # fillchars = { eob = " "; };
      history = 100;
      infercase = true;
      linebreak = true;
      preserveindent = true;
      pumheight = 10;
      # shortmess = { append = { s = true; I = true; }; };
      showmode = false;
      showtabline = 2;
      timeoutlen = 500;
      title = true;
      # viewoptions = { remove = [ "curdir" ]; };
      virtualedit = "block";
      writebackup = false;
    };
  };
}
