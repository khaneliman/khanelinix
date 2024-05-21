{ pkgs, ... }:
{
  programs.nixvim = {
    extraPlugins = [
      (pkgs.vimUtils.buildVimPlugin {
        name = "yazi.nvim";
        src = pkgs.fetchFromGitHub {
          owner = "DreamMaoMao";
          repo = "yazi.nvim";
          rev = "b5c9390c733244b10859b940413ef9741955301a";
          hash = "sha256-/wuo95maj6WxfwPvu0AAm3JJ6ifDI/ONp2SSA6k+5WQ=";
        };
      })
    ];

    keymaps = [
      {
        mode = "n";
        key = "<leader>ty";
        action = ":Yazi<CR>";
        options = {
          desc = "Toggle Yazi";
          silent = true;
        };
      }
    ];
  };
}
