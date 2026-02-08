{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.khanelinix.programs.terminal.tools.codex;
in
{
  options.khanelinix.programs.terminal.tools.codex = {
    enable = mkEnableOption "Codex configuration";
  };

  config = mkIf cfg.enable {
    programs.codex = {
      enable = true;

      settings = {
        model = "gpt-5.3-codex";
        model_reasoning_effort = "xhigh";
        personality = "pragmatic";

        projects =
          let
            khanelinixPath = "${config.home.homeDirectory}/khanelinix";
            githubPath =
              let
                documentsPath =
                  if config.xdg.userDirs.enable then
                    config.xdg.userDirs.documents
                  else
                    config.home.homeDirectory + lib.optionalString pkgs.stdenv.hostPlatform.isLinux "/Documents";
              in
              "${documentsPath}/github";
            khanelivimPath = "${githubPath}/khanelivim";
          in
          {
            "${khanelinixPath}" = {
              trust_level = "trusted";
            };
            "${khanelivimPath}" = {
              trust_level = "trusted";
            };
          };

        features = {
          shell_snapshot = true;
          collab = true;
          apps = true;
        };
      };

      custom-instructions = builtins.readFile (lib.getFile "modules/common/ai-tools/base.md");
      skills = lib.getFile "modules/common/ai-tools/skills";
    };
  };
}
