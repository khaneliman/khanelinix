{ pkgs, ... }:
{
  programs.nixvim = {
    extraPlugins = [
      # TODO: Replace when https://github.com/NixOS/nixpkgs/pull/323432 is in unstable
      (pkgs.vimUtils.buildVimPlugin {
        name = "yazi.nvim";
        src = pkgs.fetchFromGitHub {
          owner = "DreamMaoMao";
          repo = "yazi.nvim";
          rev = "0e7dce1a936b92099180ff80cbf35eb7e8a5f660";
          hash = "sha256-xKwQXwvqGBNveu94i6NW4I7L/mAnbqLmYS3Uc/6qTyw=";
        };
      })
    ];

    keymaps = [
      {
        mode = "n";
        key = "<leader>e";
        action = ":Yazi<CR>";
        options = {
          desc = "Yazi toggle";
          silent = true;
        };
      }
    ];
  };
}
