_: {
  programs.nixvim = {
    plugins = {
      direnv.enable = true;
      nix.enable = true;
      nix-develop.enable = true;
    };
  };
}
