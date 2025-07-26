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

      settings = {
        "$schema" = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json";

        version = 2;
        final_space = true;
        console_title_template = "{{ .Shell }} in {{ .Folder }}";

        blocks = [
          {
            type = "prompt";
            alignment = "left";
            segments = [
              {
                type = "os";
                style = "diamond";
                background = "#333333";
                foreground = "p:os";
                leading_diamond = "<#e4e4e4,transparent>╭─</>";
                template = " {{ if .WSL }}WSL at {{ end }}{{.Icon}} ";
              }
              {
                type = "path";
                style = "powerline";
                powerline_symbol = "";
                background = "#3465a4";
                foreground = "#e4e4e4";
                template = "  {{ .Path }} ";
                properties = {
                  style = "full";
                  home_icon = "~";
                };
              }
              {
                type = "git";
                style = "powerline";
                powerline_symbol = "";
                background = "#4e9a06";
                foreground = "#000000";
                background_templates = [
                  "{{ if or (.Working.Changed) (.Staging.Changed) }}#c4a000{{ end }}"
                  "{{ if and (gt .Ahead 0) (gt .Behind 0) }}#f26d50{{ end }}"
                  "{{ if gt .Ahead 0 }}#89d1dc{{ end }}"
                  "{{ if gt .Behind 0 }}#4e9a06{{ end }}"
                ];
                template = " {{ .UpstreamIcon }}{{ .HEAD }}{{if .BranchStatus }} {{ .BranchStatus }}{{ end }}{{ if .Working.Changed }}  {{ .Working.String }}{{ end }}{{ if and (.Working.Changed) (.Staging.Changed) }} |{{ end }}{{ if .Staging.Changed }}  {{ .Staging.String }}{{ end }}{{ if gt .StashCount 0 }}  {{ .StashCount }}{{ end }} ";
                properties = {
                  fetch_status = true;
                  fetch_upstream_icon = true;
                  fetch_stash_count = true;
                  branch_icon = " ";
                };
              }
            ];
          }
          {
            type = "prompt";
            alignment = "right";
            filler = "<#686869,transparent>.</>";
            segments = [
              {
                type = "node";
                style = "powerline";
                powerline_symbol = "";
                invert_powerline = true;
                background = "#689f63";
                foreground = "#ffffff";
                template = " {{ if .PackageManagerIcon }}{{ .PackageManagerIcon }} {{ end }}{{ .Full }}  ";
                properties = {
                  fetch_version = true;
                };
              }
              {
                type = "go";
                style = "powerline";
                powerline_symbol = "";
                invert_powerline = true;
                background = "#00acd7";
                foreground = "#111111";
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
                background = "#4063D8";
                foreground = "#111111";
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
                background = "#FFDE57";
                foreground = "#111111";
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
                background = "#AE1401";
                foreground = "#ffffff";
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
                background = "#FEAC19";
                foreground = "#ffffff";
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
                foreground = "#ffffff";
                background_templates = [
                  "{{if contains \"default\" .Profile}}#FFA400{{end}}"
                  "{{if contains \"jan\" .Profile}}#f1184c{{end}}"
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
                background = "#ffff66";
                foreground = "#111111";
                template = "  ";
              }
              {
                type = "executiontime";
                style = "powerline";
                powerline_symbol = "";
                invert_powerline = true;
                background = "#c4a000";
                foreground = "#000000";
                template = " {{ .FormattedMs }}  ";
              }
              {
                type = "exit";
                style = "powerline";
                powerline_symbol = "";
                invert_powerline = true;
                background = "#333333";
                foreground = "#4e9a06";
                foreground_templates = [ "{{ if gt .Code 0 }}#fffe00{{ end }}" ];
                background_templates = [ "{{ if gt .Code 0 }}#f1184c{{ end }}" ];
                template = " {{ if gt .Code 0 }} {{ .Code }} {{ else }}✔ {{ end }}";
                properties = {
                  always_enabled = true;
                };
              }
              {
                type = "time";
                style = "diamond";
                invert_powerline = true;
                background = "#d3d7cf";
                foreground = "#000000";
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
                foreground = "#d3d7cf";
                template = "╰─";
              }
            ];
          }
        ];
      };
    };
  };
}
