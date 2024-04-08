{ pkgs, ... }:
{
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

    extraPlugins = with pkgs.vimPlugins; [
      (pkgs.vimUtils.buildVimPlugin {
        name = "lua-utils.nvim";
        src = pkgs.fetchFromGitHub {
          owner = "nvim-neorg";
          repo = "lua-utils.nvim";
          rev = "v1.0.2";
          hash = "sha256-9ildzQEMkXKZ3LHq+khGFgRQFxlIXQclQ7QU3fcU1C4=";
        };
      })
    ];

    plugins.neorg = {
      # TODO: figure out errors and re-enable
      enable = false;

      modules = {
        "core.defaults".__empty = null;

        "core.keybinds".config.hook.__raw = # lua
          ''
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
