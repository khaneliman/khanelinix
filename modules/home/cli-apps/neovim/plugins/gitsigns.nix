_: {
  programs.nixvim = {
    plugins = {
      gitsigns = {
        enable = true;

        settings = {
          signs = {
            add.text = "+";
            change.text = "~";
          };
        };
      };
    };
  };
}
