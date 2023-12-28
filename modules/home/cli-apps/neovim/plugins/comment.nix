{ ... }: {
  programs.nixvim.plugins.comment-nvim = {
    enable = true;

    opleader = { line = "<C-b>"; };
    toggler = { line = "<C-b>"; };
  };
}
