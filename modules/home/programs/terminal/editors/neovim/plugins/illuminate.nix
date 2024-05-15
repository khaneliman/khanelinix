_: {
  programs.nixvim = {
    plugins = {
      illuminate = {
        enable = true;

        filetypesDenylist = [
          "dirvish"
          "fugitive"
          "neo-tree"
          "TelescopePrompt"
        ];
      };
    };
  };
}
