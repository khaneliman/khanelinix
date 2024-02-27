_: {
  programs.nixvim = {
    plugins.todo-comments = {
      enable = true;

      keymaps = {
        todoTelescope = {
          key = "<leader>ft";
          keywords = "TODO,FIX,NOTE";
        };
      };
    };

    # TODO: test
    # FIX: test
    # NOTE: test
  };
}
