{
  config,
  lib,

  pkgs,
  ...
}:
let
  enabledPlugins = config.programs.yazi.plugins;

  goto = import ./manager/goto.nix {
    inherit
      config
      lib
      pkgs
      ;
  };
  navigation = import ./manager/navigation.nix;
  operation = import ./manager/operation.nix { inherit config lib; };
in
{
  mgr = {
    prepend_keymap = [
      {
        on = [ "q" ];
        run = "close";
        desc = "Close the current tab; if it's the last tab, exit the process instead.";
      }
      {
        on = [ "<C-n>" ];
        run = "tab_create --current";
        desc = "Create a new tab with CWD.";
      }
      {
        on = [ "t" ];
        run = "plugin smart-tab";
        desc = "Create a tab and enter the hovered directory";
      }
    ]
    ++ lib.optional pkgs.stdenv.hostPlatform.isLinux {
      on = [ "<C-v>" ];
      run = "shell 'dragon -x -i -T \"$1\"'";
      desc = "Drag and drop files";
    }
    ++ lib.optionals (lib.hasAttr "smart-enter" enabledPlugins) [
      {
        on = [ "l" ];
        run = "plugin smart-enter";
        desc = "Enter the child directory, or open the file";
      }

      {
        on = [ "<Right>" ];
        run = "plugin smart-enter";
        desc = "Enter the child directory, or open the file";
      }
    ]
    ++ lib.optional (lib.hasAttr "mount" enabledPlugins) {
      on = [ "M" ];
      run = "plugin mount";
      desc = "Mount devices";
    }
    ++ lib.optional (lib.hasAttr "diff" enabledPlugins) {
      on = [ "<A-d>" ];
      run = "plugin diff";
      desc = "Diff the selected with the hovered file";
    }
    ++ lib.optional (lib.hasAttr "chmod" enabledPlugins) {
      on = [
        "c"
        "m"
      ];
      run = "plugin chmod";
      desc = "Chmod on selected files";
    }
    ++ lib.optional (lib.hasAttr "toggle-pane" enabledPlugins) {
      on = [ "T" ];
      run = "plugin toggle-pane min-preview";
      desc = "Hide or show preview";
    }
    # {
    #   on = [ "T" ];
    #   run = "plugin toggle-pane max-preview";
    #   desc = "Maximize or restore preview";
    # }
    ++ lib.optional (lib.hasAttr "jump-to-char" enabledPlugins) {
      on = [ "f" ];
      run = "plugin jump-to-char";
      desc = "Jump to char";
    }
    ++ lib.optional (lib.hasAttr "smart-filter" enabledPlugins) {
      on = [ "F" ];
      run = "plugin smart-filter";
      desc = "Smart filter";
    }
    ++ lib.optional (lib.hasAttr "ouch" enabledPlugins) {
      on = [ "C" ];
      run = "plugin ouch";
      desc = "Compress with outch";
    }
    ++ lib.optional config.khanelinix.suites.wlroots.enable {
      on = [ "y" ];
      run = [
        ''shell -- for path in "$@"; do echo "file://$path"; done | wl-copy -t text/uri-list''
        "yank"
      ];
    }
    ++ goto.prepend_keymap
    ++ navigation.prepend_keymap
    ++ operation.prepend_keymap;
  };
}
