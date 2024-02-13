{ config, ... }: {
  programs.nixvim.plugins = {
    yanky = {
      enable = true;
    };
  };
}
