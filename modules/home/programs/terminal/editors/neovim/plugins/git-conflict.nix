_: {
  programs.nixvim = {
    plugins = {
      git-conflict = {
        enable = true;

        settings = {
          default_mappings = {
            ours = "co";
            theirs = "ct";
            none = "c0";
            both = "cb";
            next = "]x";
            prev = "[x";
          };
        };
      };
    };
  };
}
