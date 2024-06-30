{ pkgs, ... }:
{
  programs.nixvim = {
    extraPlugins = [
      # TODO: Replace when https://github.com/NixOS/nixpkgs/pull/323432 is in unstable
      (pkgs.vimUtils.buildVimPlugin {
        name = "yazi.nvim";
        src = pkgs.fetchFromGitHub {
          owner = "mikavilpas";
          repo = "yazi.nvim";
          rev = "05849f390175f2ba8fd277b224d4fd9e35455895";
          hash = "sha256-zj+lmxsOEW+YaCk5hb7u454gACUmqYPA/IeW6av4D7k=";
        };
      })
    ];

    keymaps = [
      {
        mode = "n";
        key = "<leader>e";
        action.__raw = ''
          function()
            require('yazi').yazi()
          end
        '';
        options = {
          desc = "Yazi toggle";
          silent = true;
        };
      }
    ];
  };
}
