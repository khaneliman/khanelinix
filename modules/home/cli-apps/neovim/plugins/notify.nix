{ ... }: {
  programs.nixvim = {
    plugins.notify = {
      enable = true;
    };
  };
}
