{
  pkgs,
  config,
  lib,
  ...
}:
{
  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [ vim-wakatime ];
  };

  sops.secrets = {
    wakatime = {
      sopsFile = lib.snowfall.fs.get-file "secrets/khaneliman/default.yaml";
      path = "${config.home.homeDirectory}/.wakatime.cfg";
    };
  };
}
