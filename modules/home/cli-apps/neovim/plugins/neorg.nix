_: {
  programs.nixvim = {
    autoCmd = [
      {
        event = "FileType";
        pattern = "norg";
        command = "setlocal conceallevel=1";
      }
      {
        event = "BufWritePre";
        pattern = "*.norg";
        command = "normal gg=G``zz";
      }
    ];

    plugins.neorg = {
      enable = true;

      modules = {
        "core.defaults".__empty = null;

        "core.keybinds".config.hook.__raw = ''
          function(keybinds)
            keybinds.unmap('norg', 'n', '<C-s>')

            keybinds.map(
              'norg',
              'n',
              '<leader>c',
              ':Neorg toggle-concealer<CR>',
              {silent=true}
            )
          end
        '';

        "core.dirman".config.workspaces = {
          notes = "~/notes";
          nix = "~/perso/nix/notes";
        };

        "core.concealer".__empty = null;
        "core.completion".config.engine = "nvim-cmp";
      };
    };
  };
}
