{ pkgs, ... }:
{
  programs.nixvim = {
    extraPlugins = [
      # TODO: Replace when https://github.com/NixOS/nixpkgs/pull/323435 is in nixos-unstable
      (pkgs.vimUtils.buildVimPlugin {
        name = "precognition.nvim";
        src = pkgs.fetchFromGitHub {
          owner = "tris203";
          repo = "precognition.nvim";
          rev = "2a566f03eb06859298eff837f3a6686dfa5304a5";
          hash = "sha256-XLcyRB4ow5nPoQ0S29bx0utV9Z/wogg7c3rozYSqlWE=";
        };
      })
    ];

    keymaps = [
      {
        mode = "n";
        key = "<leader>uP";
        action.__raw = ''
          function()
            if require("precognition").toggle() then
                vim.notify("precognition on")
            else
                vim.notify("precognition off")
            end
          end
        '';

        options = {
          desc = "Precognition Toggle";
          silent = true;
        };
      }
    ];
  };
}
