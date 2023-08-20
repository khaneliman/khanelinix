{ options
, config
, lib
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.cli-apps.micro;
in
{
  options.khanelinix.cli-apps.micro = with types; {
    enable = mkBoolOpt false "Whether or not to enable micro.";
    default = mkBoolOpt false "Whether to set micro as the session EDITOR";
  };

  config = mkIf cfg.enable {
    programs.micro = {
      enable = true;

      settings = {
        colorscheme = "catppuccin-macchiato";
      };
    };

    programs.zsh.shellAliases.vimdiff = mkIf cfg.default "micro -d";
    programs.bash.shellAliases.vimdiff = mkIf cfg.default "micro -d";
    programs.fish.shellAliases.vimdiff = mkIf cfg.default "micro -d";


    home.sessionVariables = {
      EDITOR = mkIf cfg.default "micro";
    };

    xdg.configFile."micro/colorschemes" = {
      source = lib.cleanSourceWith {
        filter = name: _type:
          let
            baseName = baseNameOf (toString name);
          in
          (lib.hasSuffix ".micro" baseName);
        src = lib.cleanSource ./.;
      };

      recursive = true;
    };
  };
}
