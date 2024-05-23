{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.programs.terminal.tools.lsd;

  aliases = {

    ls = "${pkgs.lsd}/bin/lsd -al";
    lt = "${pkgs.lsd}/bin/lsd --tree";
    llt = "${pkgs.lsd}/bin/lsd -l --tree";
  };
in
{
  options.${namespace}.programs.terminal.tools.lsd = {
    enable = mkBoolOpt false "Whether or not to enable lsd.";
  };

  config = mkIf cfg.enable {
    programs.lsd = {
      enable = true;

      settings = {
        blocks = [
          "permission"
          "user"
          "group"
          "size"
          "date"
          "name"
        ];
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

    home.shellAliases = aliases;
  };
}
