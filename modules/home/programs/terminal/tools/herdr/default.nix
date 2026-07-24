{
  config,
  lib,
  pkgs,

  ...
}:
let
  cfg = config.khanelinix.programs.terminal.tools.herdr;
in
{
  options.khanelinix.programs.terminal.tools.herdr.enable =
    lib.mkEnableOption "Herdr agent multiplexer";

  config = lib.mkIf cfg.enable {
    programs.herdr = {
      enable = true;
      package = pkgs.herdr;
      settings = {
        onboarding = false;
        theme = {
          auto_switch = true;
          name = "tokyo-night";
        };
        ui = {
          agent_panel_sort = "priority";
          hide_tab_bar_when_single_tab = true;
          prompt_new_tab_name = false;
          sidebar_width = 32;
          toast.delivery = "terminal";
        };
        update.version_check = false;
      };
    };
  };
}
