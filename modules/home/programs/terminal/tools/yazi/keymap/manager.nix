{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  enabledPlugins = config.programs.yazi.plugins;

  goto = import ./manager/goto.nix {
    inherit
      config
      lib
      namespace
      pkgs
      ;
  };
  navigation = import ./manager/navigation.nix;
  operation = import ./manager/operation.nix;
in
{
  manager = {
    prepend_keymap =
      [
        {
          on = [ "l" ];
          run = "plugin smart-enter";
          desc = "Enter the child directory, or open the file";
        }
        {
          on = [ "M" ];
          run = "plugin mount";
          desc = "Mount devices";
        }
        {
          on = [ "<Right>" ];
          run = "plugin smart-enter";
          desc = "Enter the child directory, or open the file";
        }
        {
          on = [ "<C-v>" ];
          run = "shell 'dragon -x -i -T \"$1\"'";
          desc = "Drag and drop files";
        }
        {
          on = [ "<A-d>" ];
          run = "plugin diff";
          desc = "Diff the selected with the hovered file";
        }
        {
          on = [
            "c"
            "m"
          ];
          run = "plugin chmod";
          desc = "Chmod on selected files";
        }
        {
          on = [ "T" ];
          run = "plugin toggle-pane min-preview";
          desc = "Hide or show preview";
        }
        # {
        #   on = [ "T" ];
        #   run = "plugin toggle-pane max-preview";
        #   desc = "Maximize or restore preview";
        # }
        {
          on = [ "f" ];
          run = "plugin jump-to-char";
          desc = "Jump to char";
        }
        {
          on = [ "F" ];
          run = "plugin smart-filter";
          desc = "Smart filter";
        }
      ]
      ++ lib.optionals (lib.hasAttr "ouch" enabledPlugins) [
        {
          on = [ "C" ];
          run = "plugin ouch";
          desc = "Compress with outch";
        }
      ]
      ++ lib.optionals config.${namespace}.suites.wlroots.enable [
        {
          on = [ "y" ];
          run = [
            ''shell -- for path in "$@"; do echo "file://$path"; done | wl-copy -t text/uri-list''
            "yank"
          ];
        }
      ]
      ++ goto.prepend_keymap
      ++ navigation.prepend_keymap
      ++ operation.prepend_keymap;
  };
}
