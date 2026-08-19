{
  config,
  lib,
  ...
}:
let
  cfg = config.khanelinix.programs.terminal.tools.jrnl;
  notebookDirectory = config.khanelinix.programs.terminal.tools.zk.notebookDirectory;
  notebookPath = "${config.home.homeDirectory}/${notebookDirectory}";
in
{
  options.khanelinix.programs.terminal.tools.jrnl.enable = lib.mkEnableOption "jrnl journal capture";

  config = lib.mkIf cfg.enable {
    programs.jrnl = {
      enable = true;

      settings = {
        editor = "nvim";
        # A single file keeps captures inside the vault where zk and
        # Obsidian index them. A directory journal would write
        # YYYY/MM/DD.txt trees that never match zk daily notes.
        journals.default.journal = "${notebookPath}/Journal.md";
      };
    };
  };
}
