_: {
  programs.nixvim.plugins = {
    indent-blankline = {
      enable = true;

      settings = {
        scope.enabled = false;

        #TODO: figure out more transparent highlights
        indent.highlight = [
          # "rainbow1"
          # "rainbow2"
          # "rainbow3"
          # "rainbow4"
          # "rainbow5"
          # "rainbow6"
        ];
      };
    };
  };
}
