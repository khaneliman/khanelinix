{ options
, config
, lib
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.tools.lsd;
in
{
  options.khanelinix.tools.lsd = with types; {
    enable = mkBoolOpt false "Whether or not to enable lsd.";
  };

  config = mkIf cfg.enable {
    programs.lsd = {
      enable = true;
      enableAliases = true;

      settings = {
        blocks = [ "permission" "user" "group" "size" "date" "name" ];
        classic = false;
        date = "date";
        dereference = false;
        header = true;
        hyperlink = "auto";
        icons = {
          when = "auto";
          theme = "fancy";
          separator = " ";
        };
        ignore-globs = [ ".git" ];
        indicators = true;
        layout = "grid";
        # permission = "octal";
        sorting = {
          column = "name";
          reverse = false;
          dir-grouping = "first";
        };
        symlink-arrow = "=>";
        # total-size = true;
      };
    };
  };
}
