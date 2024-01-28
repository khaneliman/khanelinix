{ ... }: {
  programs.nixvim.plugins.toggleterm = {
    enable = true;
    direction = "float";
  };
}
