_: {
  programs.nixvim.plugins.mini = {
    enable = true;

    modules = {
      basics = { };
      bracketed = { };
      indentscope = { };
      surround = { };
    };
  };
}
