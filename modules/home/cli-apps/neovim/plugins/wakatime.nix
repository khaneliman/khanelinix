{ pkgs, ... }:
{
  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [
      vim-wakatime
    ];
  };

  # TODO: figure out why i can't from within imports =
  # sops.secrets = {
  #   wakatime = {
  #     sopsFile = ../../../../../../secrets/khaneliman/default.yaml;
  #     path = "${config.home.homeDirectory}/.wakatime.cfg";
  #   };
  # };
}
