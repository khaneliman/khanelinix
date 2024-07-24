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
          git = { };
          icons = { };
          pairs = { };
        };
      };
    };
  };
}
