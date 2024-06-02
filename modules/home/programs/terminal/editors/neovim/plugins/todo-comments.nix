_: {
  programs.nixvim = {
    plugins.todo-comments = {
      enable = true;

      keymaps = {
        todoTelescope = {
          key = "<leader>ft";
          keywords = "TODO,FIX,FIXME";
        };
      };
    };
  };
}
