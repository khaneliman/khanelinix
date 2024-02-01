_: {
  programs.nixvim = {
    plugins = {
      gitsigns = {
        enable = true;

        signs = {
          add.text = "+";
          change.text = "~";
        };
      };
    };
  };
}
