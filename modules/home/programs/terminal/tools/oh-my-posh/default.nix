{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.terminal.tools.oh-my-posh;
in
{
  options.khanelinix.programs.terminal.tools.oh-my-posh = {
    enable = lib.mkEnableOption "oh-my-posh";
  };

  config = mkIf cfg.enable {
    programs.oh-my-posh = {
      enable = true;

      enableBashIntegration = true;
      enableFishIntegration = true;
      enableNushellIntegration = true;
      enableZshIntegration = true;

      # Oh-my-posh configuration
      # See: https://ohmyposh.dev/docs/
      settings = {
        "$schema" = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json";

        version = 4;
        final_space = true;
        async = true;
        shell_integration = true;
        tooltips_action = "extend";
        console_title_template = "{{ .Shell }} in {{ .Folder }}";
        palette = lib.mkDefault {
          osBg = "#333333";
          osFg = "#e4e4e4";
          leading = "#e4e4e4";
          line = "#d3d7cf";

          pathBg = "#3465a4";
          pathFg = "#e4e4e4";

          gitBg = "#4e9a06";
          gitFg = "#000000";
          gitDirtyBg = "#c4a000";
          gitDivergedBg = "#f26d50";
          gitAheadBg = "#89d1dc";
          gitBehindBg = "#4e9a06";

          filler = "#686869";

          nodeBg = "#689f63";
          nodeFg = "#ffffff";
          goBg = "#00acd7";
          goFg = "#111111";
          juliaBg = "#4063D8";
          juliaFg = "#111111";
          pythonBg = "#FFDE57";
          pythonFg = "#111111";
          rubyBg = "#AE1401";
          rubyFg = "#ffffff";
          azfuncBg = "#FEAC19";
          azfuncFg = "#ffffff";

          awsFg = "#ffffff";
          awsDefaultBg = "#FFA400";
          awsJanBg = "#f1184c";

          rootBg = "#ffff66";
          rootFg = "#111111";

          executionBg = "#c4a000";
          executionFg = "#000000";

          exitBg = "#333333";
          exitFg = "#4e9a06";
          exitErrFg = "#fffe00";
          exitErrBg = "#f1184c";

          timeBg = "#d3d7cf";
          timeFg = "#000000";

          transient = "#4e9a06";
          transientError = "#f1184c";
          secondary = "#689f63";

          tooltipGit = "#4e9a06";
          tooltipAws = "#FEAC19";
        };

        # Disable transient prompt to avoid Atuin redraw/visibility conflicts.
        transient_prompt = lib.mkIf (!config.programs.atuin.enable) {
          template = "❯ ";
          foreground = "p:transient";
          foreground_templates = [ "{{ if gt .Code 0 }}p:transientError{{ end }}" ];
        };
        secondary_prompt = {
          template = "❯❯ ";
          foreground = "p:secondary";
        };
        tooltips = [
          {
            type = "git";
            style = "plain";
            foreground = "p:tooltipGit";
            tips = [
              "git"
              "jj"
              "jujutsu"
            ];
            template = "  {{ .HEAD }}{{ if .BranchStatus }} {{ .BranchStatus }}{{ end }} ";
            properties = {
              fetch_status = true;
            };
          }
          {
            type = "aws";
            style = "plain";
            foreground = "p:tooltipAws";
            tips = [
              "aws"
              "terraform"
              "terragrunt"
            ];
            template = "  {{ .Profile }}{{ if .Region }}@{{ .Region }}{{ end }} ";
            properties = {
              display_default = false;
            };
          }
        ];

        blocks = [
          {
            type = "prompt";
            alignment = "left";
            segments = [
              {
                type = "os";
                style = "diamond";
                background = "p:osBg";
                foreground = "p:osFg";
                leading_diamond = "<p:leading,transparent>╭─</>";
                template = " {{ if .WSL }}WSL at {{ end }}{{.Icon}} ";
              }
              {
                type = "path";
                style = "powerline";
                powerline_symbol = "";
                background = "p:pathBg";
                foreground = "p:pathFg";
                template = "  {{ path .Path .Location }} ";
                properties = {
                  style = "full";
                  home_icon = "~";
                };
              }
              {
                type = "git";
                style = "powerline";
                powerline_symbol = "";
                background = "p:gitBg";
                foreground = "p:gitFg";
                timeout = 500;
                background_templates = [
                  "{{ if or (.Working.Changed) (.Staging.Changed) }}p:gitDirtyBg{{ end }}"
                  "{{ if and (gt .Ahead 0) (gt .Behind 0) }}p:gitDivergedBg{{ end }}"
                  "{{ if gt .Ahead 0 }}p:gitAheadBg{{ end }}"
                  "{{ if gt .Behind 0 }}p:gitBehindBg{{ end }}"
                ];
                template = " {{ .UpstreamIcon }}{{ .HEAD }}{{if .BranchStatus }} {{ .BranchStatus }}{{ end }}{{ if .Working.Changed }}  {{ .Working.String }}{{ end }}{{ if and (.Working.Changed) (.Staging.Changed) }} |{{ end }}{{ if .Staging.Changed }}  {{ .Staging.String }}{{ end }}{{ if gt .StashCount 0 }}  {{ .StashCount }}{{ end }} ";
                properties = {
                  fetch_status = true;
                  fetch_upstream_icon = true;
                  fetch_stash_count = true;
                  branch_icon = " ";
                };
              }
              {
                type = "jujutsu";
                style = "powerline";
                powerline_symbol = "";
                background = "p:gitBg";
                foreground = "p:gitFg";
                timeout = 500;
                properties = {
                  fetch_status = true;
                };
              }
            ];
          }
          {
            type = "prompt";
            alignment = "right";
            overflow = "hide";
            filler = "{{ if .Overflow }}<p:filler,transparent> </>{{ else }}<p:filler,transparent>.</>{{ end }}";
            segments = [
              {
                type = "node";
                style = "powerline";
                powerline_symbol = "";
                invert_powerline = true;
                background = "p:nodeBg";
                foreground = "p:nodeFg";
                template = " {{ if .PackageManagerIcon }}{{ .PackageManagerIcon }} {{ end }}{{ .Full }}  ";
                properties = {
                  fetch_version = true;
                  fetch_package_manager = true;
                };
              }
              {
                type = "go";
                style = "powerline";
                powerline_symbol = "";
                invert_powerline = true;
                background = "p:goBg";
                foreground = "p:goFg";
                template = " {{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }}  ";
                properties = {
                  fetch_version = true;
                };
              }
              {
                type = "julia";
                style = "powerline";
                powerline_symbol = "";
                invert_powerline = true;
                background = "p:juliaBg";
                foreground = "p:juliaFg";
                template = " {{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }}  ";
                properties = {
                  fetch_version = true;
                };
              }
              {
                type = "python";
                style = "powerline";
                powerline_symbol = "";
                invert_powerline = true;
                background = "p:pythonBg";
                foreground = "p:pythonFg";
                template = " {{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }}  ";
                properties = {
                  display_mode = "files";
                  fetch_virtual_env = false;
                };
              }
              {
                type = "ruby";
                style = "powerline";
                powerline_symbol = "";
                invert_powerline = true;
                background = "p:rubyBg";
                foreground = "p:rubyFg";
                template = " {{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }}  ";
                properties = {
                  display_mode = "files";
                  fetch_version = true;
                };
              }
              {
                type = "azfunc";
                style = "powerline";
                powerline_symbol = "";
                invert_powerline = true;
                background = "p:azfuncBg";
                foreground = "p:azfuncFg";
                template = " {{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }} ";
                properties = {
                  display_mode = "files";
                  fetch_version = false;
                };
              }
              {
                type = "aws";
                style = "powerline";
                powerline_symbol = "";
                invert_powerline = true;
                foreground = "p:awsFg";
                timeout = 500;
                background_templates = [
                  "{{if contains \"default\" .Profile}}p:awsDefaultBg{{end}}"
                  "{{if contains \"jan\" .Profile}}p:awsJanBg{{end}}"
                ];
                template = " {{ .Profile }}{{ if .Region }}@{{ .Region }}{{ end }}  ";
                properties = {
                  display_default = false;
                };
              }
              {
                type = "root";
                style = "powerline";
                powerline_symbol = "";
                invert_powerline = true;
                background = "p:rootBg";
                foreground = "p:rootFg";
                template = "  ";
              }
              {
                type = "executiontime";
                style = "powerline";
                powerline_symbol = "";
                invert_powerline = true;
                background = "p:executionBg";
                foreground = "p:executionFg";
                template = " {{ .FormattedMs }}  ";
              }
              {
                type = "exit";
                style = "powerline";
                powerline_symbol = "";
                invert_powerline = true;
                background = "p:exitBg";
                foreground = "p:exitFg";
                foreground_templates = [ "{{ if gt .Code 0 }}p:exitErrFg{{ end }}" ];
                background_templates = [ "{{ if gt .Code 0 }}p:exitErrBg{{ end }}" ];
                template = " {{ if gt .Code 0 }} {{ .Code }} {{ else }}✔ {{ end }}";
                properties = {
                  always_enabled = true;
                };
              }
              {
                type = "time";
                style = "diamond";
                invert_powerline = true;
                background = "p:timeBg";
                foreground = "p:timeFg";
                template = " {{ .CurrentDate | date .Format }}  ";
                properties = {
                  time_format = "03:04:05 PM";
                };
              }
            ];
          }
          {
            type = "prompt";
            alignment = "left";
            newline = true;
            segments = [
              {
                type = "text";
                style = "plain";
                foreground = "p:line";
                template = "╰─";
              }
            ];
          }
        ];
      };
    };
  };
}
