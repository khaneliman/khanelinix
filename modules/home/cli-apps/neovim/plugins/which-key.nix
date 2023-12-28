{ ... }: {
  programs.nixvim = {
    plugins.which-key = {
      enable = true;
      # ignoreMissing = true;
    };
  };
}
