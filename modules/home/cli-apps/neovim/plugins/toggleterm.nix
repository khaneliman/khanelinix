{ ... }: {
  programs.nixvim.plugins.toggleterm = {
    enable = true;
    direction = "float";

    openMapping = "<leader>,";
  };
}
