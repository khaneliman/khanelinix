_: {
  programs.nixvim = {
    plugins = {
      nix.enable = true;
      nix-develop.enable = true;
    };
  };
}
