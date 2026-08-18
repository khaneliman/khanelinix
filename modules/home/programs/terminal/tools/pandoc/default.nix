{
  config,
  lib,
  pkgs,

  ...
}:
let
  cfg = config.khanelinix.programs.terminal.tools.pandoc;
  notebookDirectory = config.khanelinix.programs.terminal.tools.zk.notebookDirectory;
  notebookPath = "${config.home.homeDirectory}/${notebookDirectory}";

  knowledgeExport = pkgs.writeShellApplication {
    name = "knowledge-export";
    runtimeInputs = [ config.programs.pandoc.finalPackage ];
    text = ''
      if [[ $# -lt 1 || $# -gt 2 ]]; then
        echo "Usage: knowledge-export SOURCE.md [OUTPUT.docx|OUTPUT.pptx|OUTPUT.html]" >&2
        exit 2
      fi

      source_file="$1"
      if [[ ! -f "$source_file" ]]; then
        echo "Source file does not exist: $source_file" >&2
        exit 1
      fi

      output_file="''${2:-"''${source_file%.*}.docx"}"
      exec pandoc "$source_file" --output "$output_file"
    '';
  };
in
{
  options.khanelinix.programs.terminal.tools.pandoc = {
    enable = lib.mkEnableOption "Pandoc document publishing";
  };

  config = lib.mkIf cfg.enable {
    programs.pandoc = {
      enable = true;

      defaults = {
        from = "markdown+yaml_metadata_block";
        standalone = true;
        wrap = "preserve";
        resource-path = [
          "."
          notebookPath
          "${notebookPath}/Attachments"
        ];
        metadata.lang = "en-US";
      };
    };

    home.packages = [ knowledgeExport ];
  };
}
