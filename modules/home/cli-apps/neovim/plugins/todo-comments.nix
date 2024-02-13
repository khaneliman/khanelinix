_: {
  programs.nixvim = {
    plugins.todo-comments = {
      enable = true;

      keymaps = {
        todoTelescope = {
          key = "<C-t>";
          keywords = "TODO,FIX,NOTE";
        };
      };
    };

    # TODO: test
    # FIX: test
    # NOTE: test
  };
}
