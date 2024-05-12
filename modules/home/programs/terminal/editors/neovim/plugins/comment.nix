_: {
  programs.nixvim.plugins.comment = {
    enable = true;

    settings = {
      opleader = {
        # block = "<leader>/";
        line = "<leader>/";
      };
      toggler = {
        # block = "<leader>/";
        line = "<leader>/";
      };
    };
  };
}
