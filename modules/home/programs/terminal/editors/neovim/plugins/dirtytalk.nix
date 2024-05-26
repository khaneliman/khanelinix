{ pkgs, ... }:
{
  programs.nixvim = {
    extraPlugins = [
      (pkgs.vimUtils.buildVimPlugin {
        name = "vim-dirtytalk";
        src = pkgs.fetchFromGitHub {
          owner = "psliwka";
          repo = "vim-dirtytalk";
          rev = "aa57ba902b04341a04ff97214360f56856493583";
          hash = "sha256-azU5jkv/fD/qDDyCU1bPNXOH6rmbDauG9jDNrtIXc0Y=";
        };
      })
    ];

    opts.spelllang = [
      "en_us"
      "programming"
    ];
  };
}
