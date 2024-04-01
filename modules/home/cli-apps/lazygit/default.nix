{ config
, lib
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.cli-apps.lazygit;

  fromYAML = f:
    let
      jsonFile =
        pkgs.runCommand "lazygit yaml to attribute set"
          {
            nativeBuildInputs = [ pkgs.jc ];
          } /* bash */ ''
          jc --yaml < "${f}" > "$out"
        '';
    in
    builtins.elemAt (builtins.fromJSON (builtins.readFile jsonFile)) 0;
in
{
  options.khanelinix.cli-apps.lazygit = {
    enable = mkBoolOpt false "Whether or not to enable lazygit.";
  };

  config = mkIf cfg.enable {
    programs.lazygit = {
      enable = true;

      settings = {
        gui = fromYAML (pkgs.catppuccin + "/lazygit/themes/${config.khanelinix.desktop.theme.selectedTheme.accent}.yml");
        git = {
          overrideGpg = true;
        };
      };
    };

    home.shellAliases = {
      lg = "lazygit";
    };
  };
}
