{ pkgs, ... }:
{
  programs.nixvim = {
    extraPlugins = [
      (pkgs.vimUtils.buildVimPlugin {
        name = "markview.nvim";
        src = pkgs.fetchFromGitHub {
          owner = "OXY2DEV";
          repo = "markview.nvim";
          rev = "f60219dce7283192d549f21847fcf8537bf6d260";
          hash = "sha256-E1lHSjbnOOIeieaFJ+INvxJHCbfVS3mwbQ6wrlKeGSQ=";
        };
      })
    ];

    extraConfigLuaPre = # lua
      ''
        require("markview").setup()
      '';
  };
}
