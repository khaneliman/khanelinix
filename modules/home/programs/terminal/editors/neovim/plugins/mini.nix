_: {
  programs.nixvim = {
    plugins = {
      mini = {
        enable = true;

        modules = {
          ai = { };
          align = { };
          basics = { };
          bracketed = { };
          # TODO: see which i prefer, which-key or this
          # clue = { };
          git = { };
          pairs = { };
        };
      };
    };
  };
}
