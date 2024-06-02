_: {
  programs.nixvim = {
    plugins = {
      mini = {
        enable = true;

        modules = {
          comment = {
            mappings = {
              comment = "<leader>/";
              comment_line = "<leader>/";
              comment_visual = "<leader>/";
              textobject = "<leader>/";
            };
          };
        };
      };
    };
  };
}
