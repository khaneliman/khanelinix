{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.programs.terminal.tools.navi;
in
{
  options.${namespace}.programs.terminal.tools.navi = {
    enable = lib.mkEnableOption "navi";
  };

  config = mkIf cfg.enable {
    programs.navi = {
      enable = true;

      settings = {
        style = {
          tag = {
            color = "green"; # text color. possible values: https://bit.ly/3gloNNI
            # width_percentage = 26; # column width relative to the terminal window
            # min_width = 20; # minimum column width as number of characters
          };
          comment = {
            color = "blue";
            # width_percentage = 42;
            # min_width = 45;
          };
          snippet = {
            color = "white";
          };
        };
      };
    };
  };
}
