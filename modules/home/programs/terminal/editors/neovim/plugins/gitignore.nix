{ config, lib, ... }:
let
  inherit (lib) mkIf;

  cfg = config.programs.nixvim.plugins.gitignore;
in
{
  programs.nixvim = {
    plugins = {
      gitignore = {
        enable = true;
      };
    };

    keymaps = mkIf cfg.enable [
      {
        mode = "n";
        key = "<leader>gi";
        action.__raw = # lua
          ''require('gitignore').generate'';
        options = {
          desc = "Gitignore generate";
          silent = true;
        };
      }
    ];
  };
}
