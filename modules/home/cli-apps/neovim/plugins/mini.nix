_: {
  programs.nixvim.plugins.mini = {
    enable = true;

    modules = {
      surround = { };
      indentscope = { };
    };
  };
}
