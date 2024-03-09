_: {
  programs.nixvim.plugins.mini = {
    enable = true;

    modules = {
      basics = { };
      bracketed = { };
      indentscope = { };
      map = {
        # __raw = lua code
        # __unkeyed.* = no key, just the value
        integrations = {
          "__unkeyed.builtin_search".__raw = "require('mini.map').gen_integration.builtin_search()";
          "__unkeyed.gitsigns".__raw = "require('mini.map').gen_integration.gitsigns()";
          "__unkeyed.diagnostic".__raw = "require('mini.map').gen_integration.diagnostic()";
        };

        window = {
          winblend = 0;
        };
      };
      surround = { };
    };
  };
}
