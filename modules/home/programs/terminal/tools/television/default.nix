{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.terminal.tools.television;
in
{
  options.khanelinix.programs.terminal.tools.television = {
    enable = lib.mkEnableOption "television";
  };

  config = mkIf cfg.enable {
    programs.television = {
      enable = true;
      # TODO: remove after https://nixpkgs-tracker.ocfox.me/?pr=472586
      package = pkgs.television.overrideAttrs (old: {
        postInstall = old.postInstall + ''
          install -Dm644 television/utils/shell/completion.* -t $out/share/television/
        '';
      });

      settings = {
        ui = {
          use_nerd_font_icons = true;
          theme = lib.mkIf (!config.khanelinix.theme.catppuccin.enable) "catppuccin";
        };
      };
    };
  };
}
