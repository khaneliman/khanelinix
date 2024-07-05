{ pkgs, ... }:
{
  programs.nixvim = {
    extraPlugins = [
      (pkgs.vimUtils.buildVimPlugin {
        name = "markview.nvim";
        src = pkgs.fetchFromGitHub {
          owner = "OXY2DEV";
          repo = "markview.nvim";
          rev = "00b988f92e52d8cb75a7f2cc61042d851a358fd7";
          hash = "sha256-jUZ6dH4JMVs5Gm6Mp/wQAtkjoXEUElNQ0I8TxOdGwaU=";
        };
      })
    ];

    extraConfigLuaPre = # lua
      ''
        require("markview").setup()
      '';
  };
}
