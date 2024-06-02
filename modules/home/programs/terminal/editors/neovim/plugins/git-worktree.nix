{ config, lib, ... }:
let
  inherit (lib) mkIf;

  cfg = config.programs.nixvim.plugins.git-worktree;
in
{
  programs.nixvim = {
    plugins = {
      git-worktree = {
        enable = true;
        enableTelescope = true;
      };

      which-key.registrations."<leader>"."g"."W" = mkIf (cfg.enableTelescope && cfg.enable) {
        name = "󰙅 Worktree";
      };
    };

    keymaps = mkIf cfg.enableTelescope [
      {
        mode = "n";
        key = "<leader>fg";
        action = ":Telescope git_worktree<CR>";
        options = {
          desc = "Git Worktree";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>gWc";
        action.__raw = # lua
          ''
            function()
              require('telescope').extensions.git_worktree.create_git_worktree()
            end
          '';
        options = {
          desc = "Create worktree";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>gWs";
        action.__raw = # lua
          ''
            function()
              require('telescope').extensions.git_worktree.git_worktrees()
            end
          '';
        options = {
          desc = "Switch / Delete worktree";
          silent = true;
        };
      }
    ];
  };
}
