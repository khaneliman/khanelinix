_: {
  programs.nixvim.plugins.comment = {
    enable = true;

    settings = {
      opleader = { line = "<leader>/"; };
      toggler = { line = "<leader>/"; };
    };
  };
}
