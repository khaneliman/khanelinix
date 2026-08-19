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

  yamlFormat = pkgs.formats.yaml { };

  # Pandoc writes out its own bundled reference file, so a generated document
  # carries stock pandoc styling until the user brands the file. The value is
  # the stable path, which referenceDocx and referencePptx can replace with a
  # branded template without touching the export wrapper.
  generatedReferenceDoc =
    format:
    pkgs.runCommand "pandoc-reference-${format}" { } ''
      ${lib.getExe config.programs.pandoc.package} \
        --output "$out" \
        --print-default-data-file "reference.${format}"
    '';

  # Slide decks carry no section numbering or table of contents, so these apply
  # to the paged document formats only.
  documentDefaults = {
    toc = true;
    number-sections = true;
  };

  # Pandoc merges --defaults files in order, so these layer over the Home
  # Manager defaults file that programs.pandoc.finalPackage already passes.
  formatDefaults = {
    docx = yamlFormat.generate "pandoc-docx-defaults.yaml" (
      documentDefaults // { reference-doc = cfg.referenceDocx; }
    );
    pptx = yamlFormat.generate "pandoc-pptx-defaults.yaml" { reference-doc = cfg.referencePptx; };
    html = yamlFormat.generate "pandoc-html-defaults.yaml" documentDefaults;
  };

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

      case "''${output_file##*.}" in
        docx | DOCX) format_defaults="${formatDefaults.docx}" ;;
        pptx | PPTX) format_defaults="${formatDefaults.pptx}" ;;
        html | htm | HTML | HTM) format_defaults="${formatDefaults.html}" ;;
        *) format_defaults="" ;;
      esac

      if [[ -z "$format_defaults" ]]; then
        exec pandoc "$source_file" --output "$output_file"
      fi

      exec pandoc "$source_file" --defaults "$format_defaults" --output "$output_file"
    '';
  };
in
{
  options.khanelinix.programs.terminal.tools.pandoc = {
    enable = lib.mkEnableOption "Pandoc document publishing";

    referenceDocx = lib.mkOption {
      type = lib.types.path;
      default = generatedReferenceDoc "docx";
      defaultText = lib.literalExpression "pandoc reference.docx generated from programs.pandoc.package";
      description = ''
        Reference document that supplies Word styles for docx exports.
        Point this at a branded template to change deliverable styling.
      '';
    };

    referencePptx = lib.mkOption {
      type = lib.types.path;
      default = generatedReferenceDoc "pptx";
      defaultText = lib.literalExpression "pandoc reference.pptx generated from programs.pandoc.package";
      description = ''
        Reference presentation that supplies slide layouts for pptx exports.
        Point this at a branded template to change deliverable styling.
      '';
    };
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
