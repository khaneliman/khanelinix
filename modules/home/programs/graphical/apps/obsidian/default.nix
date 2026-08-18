{
  config,
  lib,

  ...
}:
let
  cfg = config.khanelinix.programs.graphical.apps.obsidian;
  vaultPath = "${config.home.homeDirectory}/${cfg.vaultDirectory}";
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
  options.khanelinix.programs.graphical.apps.obsidian = {
    enable = lib.mkEnableOption "Obsidian knowledge workspace";

    vaultDirectory = lib.mkOption {
      type = lib.types.str;
      default = config.khanelinix.programs.terminal.tools.zk.notebookDirectory;
      defaultText = lib.literalExpression "config.khanelinix.programs.terminal.tools.zk.notebookDirectory";
      description = "Obsidian vault path relative to the home directory.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.obsidian = {
      enable = true;
      cli.enable = true;

      defaultSettings = {
        app = {
          alwaysUpdateLinks = true;
          attachmentFolderPath = "Attachments";
          newLinkFormat = "relative";
          useMarkdownLinks = true;
        };

        corePlugins = [
          "backlink"
          "bases"
          "bookmarks"
          "canvas"
          "command-palette"
          {
            name = "daily-notes";
            settings = {
              folder = "Daily";
              format = "YYYY-MM-DD";
              template = "Templates/daily";
            };
          }
          "file-explorer"
          "file-recovery"
          "global-search"
          "graph"
          "note-composer"
          "outgoing-link"
          "outline"
          "page-preview"
          "properties"
          "switcher"
          "tag-pane"
          {
            name = "templates";
            settings = {
              folder = "Templates";
              dateFormat = "YYYY-MM-DD";
              timeFormat = "HH:mm";
            };
          }
          "workspaces"
        ];
      };

      vaults.knowledge.target = cfg.vaultDirectory;
    };

    home.activation.obsidianTemplates = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      template_directory=${lib.escapeShellArg "${vaultPath}/Templates"}
      run mkdir -p "$template_directory"

      for template_source in ${
        lib.escapeShellArgs (map (name: ./templates + "/${name}.md") templateNames)
      }; do
        template_target="$template_directory/$(basename "$template_source")"
        if [[ ! -e "$template_target" && ! -L "$template_target" ]]; then
          run install -m 0644 "$template_source" "$template_target"
        fi
      done
    '';
  };
}
