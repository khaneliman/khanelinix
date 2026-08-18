{
  config,
  lib,

  ...
}:
let
  cfg = config.khanelinix.programs.terminal.tools.zk;
  notebookPath = "${config.home.homeDirectory}/${cfg.notebookDirectory}";
  templateNames = [
    "daily"
    "decision"
    "meeting"
    "note"
    "project"
    "requirement"
  ];
in
{
  options.khanelinix.programs.terminal.tools.zk = {
    enable = lib.mkEnableOption "zk knowledge workspace";

    notebookDirectory = lib.mkOption {
      type = lib.types.str;
      default = "Documents/Knowledge";
      description = "Knowledge workspace path relative to the home directory.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.zk = {
      enable = true;

      settings = {
        notebook.dir = notebookPath;

        note = {
          language = "en";
          default-title = "Untitled";
          filename = "{{id}}-{{slug title}}";
          extension = "md";
          template = "note.md";
          id-charset = "alphanum";
          id-length = 6;
          id-case = "lower";
        };

        group = {
          daily = {
            paths = [ "Daily" ];
            note = {
              filename = "{{format-date now '%Y-%m-%d'}}";
              template = "daily.md";
            };
          };
          decision = {
            paths = [ "Decisions" ];
            note = {
              filename = "ADR-{{id}}-{{slug title}}";
              template = "decision.md";
            };
          };
          meeting = {
            paths = [ "Meetings" ];
            note = {
              filename = "{{format-date now '%Y-%m-%d'}}-{{slug title}}";
              template = "meeting.md";
            };
          };
          project = {
            paths = [ "Projects" ];
            note.template = "project.md";
          };
          requirement = {
            paths = [ "Requirements" ];
            note = {
              filename = "REQ-{{id}}-{{slug title}}";
              template = "requirement.md";
            };
          };
        };

        format.markdown = {
          hashtags = true;
          colon-tags = false;
          link-format = "markdown";
          link-drop-extension = true;
        };

        tool = {
          pager = "less -FIRX";
          fzf-preview = "bat -p --color always {-1}";
        };

        filter = {
          recents = "--sort modified- --modified-after 'last two weeks'";
          requirements = "Requirements --sort created-";
          projects = "Projects --sort modified-";
        };

        alias = {
          daily = ''zk new --no-input "$ZK_NOTEBOOK_DIR/Daily"'';
          decision = ''zk new "$ZK_NOTEBOOK_DIR/Decisions" --title "$*"'';
          meeting = ''zk new "$ZK_NOTEBOOK_DIR/Meetings" --title "$*"'';
          project = ''zk new "$ZK_NOTEBOOK_DIR/Projects" --title "$*"'';
          requirement = ''zk new "$ZK_NOTEBOOK_DIR/Requirements" --title "$*"'';
          recent = "zk edit --interactive --sort modified- --modified-after 'last two weeks'";
        };

        lsp.diagnostics = {
          wiki-title = "hint";
          dead-link = "error";
          missing-backlink = {
            level = "warning";
            position = "bottom";
          };
        };
      };
    };

    xdg.configFile = builtins.listToAttrs (
      map (name: {
        name = "zk/templates/${name}.md";
        value.source = ./templates/${name}.md;
      }) templateNames
    );

    home.activation.zkNotebook = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      run mkdir -p ${
        lib.escapeShellArgs (
          map (directory: "${notebookPath}/${directory}") [
            "Daily"
            "Decisions"
            "Attachments"
            "Meetings"
            "Projects"
            "Requirements"
          ]
        )
      }

      workspace_readme=${lib.escapeShellArg "${notebookPath}/README.md"}
      if [[ ! -e "$workspace_readme" && ! -L "$workspace_readme" ]]; then
        run install -m 0644 ${lib.escapeShellArg ./workspace.md} "$workspace_readme"
      fi
    '';
  };
}
