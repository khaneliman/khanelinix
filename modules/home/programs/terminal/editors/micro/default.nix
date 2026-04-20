{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.terminal.editors.micro;
in
{
  options.khanelinix.programs.terminal.editors.micro = {
    enable = lib.mkEnableOption "micro";
    default = lib.mkEnableOption "setting micro as the session EDITOR";
  };

  config = mkIf cfg.enable {
    home.shellAliases = lib.mkIf cfg.default {
      vimdiff = "micro -d";
    };

    programs = {
      micro = {
        # Micro documentation
        # See: https://github.com/zyedidia/micro/blob/master/runtime/help/options.md
        enable = true;

        settings = {
          colorscheme = "catppuccin-macchiato";
        };
      };
    };

    home.sessionVariables = {
      EDITOR = mkIf cfg.default "micro";
    };

    xdg.configFile."micro/colorschemes" = {
      source = lib.cleanSourceWith {
        filter =
          name: _type:
          let
            baseName = baseNameOf (toString name);
          in
          lib.hasSuffix ".micro" baseName;
        src = lib.cleanSource ./.;
      };

      recursive = true;
    };
  };
}
