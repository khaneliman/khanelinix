{ config, lib, ... }:
{
  programs.nixvim = {

    plugins = {
      undotree = {
        enable = true;

        settings = {
          CursorLine = true;
          DiffAutoOpen = true;
          DiffCommand = "diff";
          DiffpanelHeight = 10;
          HelpLine = true;
          HighlightChangedText = true;
          HighlightChangedWithSign = true;
          HighlightSyntaxAdd = "DiffAdd";
          HighlightSyntaxChange = "DiffChange";
          HighlightSyntaxDel = "DiffDelete";
          RelativeTimestamp = true;
          SetFocusWhenToggle = true;
          ShortIndicators = false;
          TreeNodeShape = "*";
          TreeReturnShape = "\\";
          TreeSplitShape = "/";
          TreeVertShape = "|";
        };
      };
    };

    keymaps = lib.mkIf config.programs.nixvim.plugins.undotree.enable [
      {
        mode = "n";
        key = "<leader>uu";
        action = ":UndotreeToggle<CR>";
        options = {
          desc = "Undotree toggle";
          silent = true;
        };
      }
    ];
  };
}
