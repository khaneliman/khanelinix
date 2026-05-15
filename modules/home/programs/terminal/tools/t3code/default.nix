{
  config,
  lib,
  ...
}:
let
  cfg = config.khanelinix.programs.terminal.tools.t3code;
in
{
  options.khanelinix.programs.terminal.tools.t3code = {
    enable = lib.mkEnableOption "T3 Code configuration";
  };

  config = lib.mkIf cfg.enable {
    programs.t3code = {
      enable = true;

      userSettings = {
        addProjectBaseDirectory = "~/Documents/github";
      };

      keybindings = [
        {
          key = "mod+j";
          command = "terminal.toggle";
        }
        {
          key = "mod+d";
          command = "terminal.split";
          when = "terminalFocus";
        }
        {
          key = "mod+n";
          command = "terminal.new";
          when = "terminalFocus";
        }
        {
          key = "mod+w";
          command = "terminal.close";
          when = "terminalFocus";
        }
        {
          key = "mod+d";
          command = "diff.toggle";
          when = "!terminalFocus";
        }
        {
          key = "mod+k";
          command = "commandPalette.toggle";
          when = "!terminalFocus";
        }
        {
          key = "mod+n";
          command = "chat.new";
          when = "!terminalFocus";
        }
        {
          key = "mod+shift+o";
          command = "chat.new";
          when = "!terminalFocus";
        }
        {
          key = "mod+shift+n";
          command = "chat.newLocal";
          when = "!terminalFocus";
        }
        {
          key = "mod+shift+m";
          command = "modelPicker.toggle";
          when = "!terminalFocus";
        }
        {
          key = "mod+o";
          command = "editor.openFavorite";
        }
        {
          key = "mod+shift+[";
          command = "thread.previous";
        }
        {
          key = "mod+shift+]";
          command = "thread.next";
        }
        {
          key = "mod+1";
          command = "thread.jump.1";
        }
        {
          key = "mod+2";
          command = "thread.jump.2";
        }
        {
          key = "mod+3";
          command = "thread.jump.3";
        }
        {
          key = "mod+4";
          command = "thread.jump.4";
        }
        {
          key = "mod+5";
          command = "thread.jump.5";
        }
        {
          key = "mod+6";
          command = "thread.jump.6";
        }
        {
          key = "mod+7";
          command = "thread.jump.7";
        }
        {
          key = "mod+8";
          command = "thread.jump.8";
        }
        {
          key = "mod+9";
          command = "thread.jump.9";
        }
        {
          key = "mod+1";
          command = "modelPicker.jump.1";
          when = "modelPickerOpen";
        }
        {
          key = "mod+2";
          command = "modelPicker.jump.2";
          when = "modelPickerOpen";
        }
        {
          key = "mod+3";
          command = "modelPicker.jump.3";
          when = "modelPickerOpen";
        }
        {
          key = "mod+4";
          command = "modelPicker.jump.4";
          when = "modelPickerOpen";
        }
        {
          key = "mod+5";
          command = "modelPicker.jump.5";
          when = "modelPickerOpen";
        }
        {
          key = "mod+6";
          command = "modelPicker.jump.6";
          when = "modelPickerOpen";
        }
        {
          key = "mod+7";
          command = "modelPicker.jump.7";
          when = "modelPickerOpen";
        }
        {
          key = "mod+8";
          command = "modelPicker.jump.8";
          when = "modelPickerOpen";
        }
        {
          key = "mod+9";
          command = "modelPicker.jump.9";
          when = "modelPickerOpen";
        }
      ];

      clientSettings = {
        settings = {
          autoOpenPlanSidebar = true;
          confirmThreadArchive = false;
          confirmThreadDelete = true;
          diffIgnoreWhitespace = true;
          diffWordWrap = false;
          favorites = [
            {
              provider = "codex";
              model = "gpt-5.5";
            }
            {
              provider = "codex";
              model = "gpt-5.4";
            }
            {
              provider = "codex";
              model = "gpt-5.3-codex-spark";
            }
          ];
          sidebarProjectGroupingMode = "repository";
          sidebarProjectSortOrder = "updated_at";
          sidebarThreadSortOrder = "updated_at";
          timestampFormat = "locale";
        };
      };
    };
  };
}
