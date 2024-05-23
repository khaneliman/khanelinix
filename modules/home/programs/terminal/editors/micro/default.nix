{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.programs.terminal.editors.micro;
in
{
  options.${namespace}.programs.terminal.editors.micro = {
    enable = mkBoolOpt false "Whether or not to enable micro.";
    default = mkBoolOpt false "Whether to set micro as the session EDITOR";
  };

  config = mkIf cfg.enable {
    programs = {
      micro = {
        enable = true;

        settings = {
          colorscheme = "catppuccin-macchiato";
        };
      };

      bash.shellAliases.vimdiff = mkIf cfg.default "micro -d";
      fish.shellAliases.vimdiff = mkIf cfg.default "micro -d";
      zsh.shellAliases.vimdiff = mkIf cfg.default "micro -d";
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
