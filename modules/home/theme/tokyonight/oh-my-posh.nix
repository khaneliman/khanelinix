{
  config,
  lib,
  ...
}:
let
  cfg = config.khanelinix.theme.tokyonight;

  tokyonight = import ./colors.nix;
  colors = tokyonight.getVariant cfg.variant;
in
{
  config = lib.mkIf cfg.enable {
    programs.oh-my-posh.settings = {
      tooltips = [
        {
          type = "git";
          style = "plain";
          foreground = colors.green;
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
          foreground = colors.orange;
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

      blocks = lib.mkForce [
        {
          type = "prompt";
          alignment = "left";
          segments = [
            {
              type = "os";
              style = "diamond";
              background = colors.bg_dark;
              foreground = colors.fg;
              leading_diamond = "<${colors.comment},transparent>╭─</>";
              trailing_diamond = "";
              template = " {{ if .WSL }}WSL at {{ end }}{{.Icon}} ";
            }
            {
              type = "path";
              style = "powerline";
              powerline_symbol = "";
              background = colors.blue;
              foreground = colors.bg;
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
              background = colors.green;
              foreground = colors.bg;
              timeout = 500;
              background_templates = [
                "{{ if or (.Working.Changed) (.Staging.Changed) }}${colors.yellow}{{ end }}"
                "{{ if and (gt .Ahead 0) (gt .Behind 0) }}${colors.orange}{{ end }}"
                "{{ if gt .Ahead 0 }}${colors.cyan}{{ end }}"
                "{{ if gt .Behind 0 }}${colors.green}{{ end }}"
              ];
              template = "  {{ .UpstreamIcon }}{{ .HEAD }}{{if .BranchStatus }} {{ .BranchStatus }}{{ end }}{{ if .Working.Changed }}  {{ .Working.String }}{{ end }}{{ if and (.Working.Changed) (.Staging.Changed) }} |{{ end }}{{ if .Staging.Changed }}  {{ .Staging.String }}{{ end }}{{ if gt .StashCount 0 }}  {{ .StashCount }}{{ end }} ";
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
              background = colors.green;
              foreground = colors.bg;
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
          filler = "{{ if .Overflow }}<${colors.bg_highlight},transparent> </>{{ else }}<${colors.bg_highlight},transparent>.</>{{ end }}";
          overflow = "hide";
          segments = [
            {
              type = "node";
              style = "powerline";
              powerline_symbol = "";
              invert_powerline = true;
              background = colors.green;
              foreground = colors.fg;
              template = "  {{ if .PackageManagerIcon }}{{ .PackageManagerIcon }} {{ end }}{{ .Full }} ";
              properties = {
                fetch_version = true;
                fetch_package_manager = true;
                min_width = 140;
              };
            }
            {
              type = "go";
              style = "powerline";
              powerline_symbol = "";
              invert_powerline = true;
              background = colors.cyan;
              foreground = colors.bg;
              template = "  {{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }} ";
              properties = {
                fetch_version = true;
                min_width = 150;
              };
            }
            {
              type = "julia";
              style = "powerline";
              powerline_symbol = "";
              invert_powerline = true;
              background = colors.blue;
              foreground = colors.bg;
              template = "  {{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }} ";
              properties = {
                fetch_version = true;
                min_width = 160;
              };
            }
            {
              type = "python";
              style = "powerline";
              powerline_symbol = "";
              invert_powerline = true;
              background = colors.yellow;
              foreground = colors.bg;
              template = "  {{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }} ";
              properties = {
                display_mode = "files";
                fetch_virtual_env = false;
                min_width = 170;
              };
            }
            {
              type = "ruby";
              style = "powerline";
              powerline_symbol = "";
              invert_powerline = true;
              background = colors.red;
              foreground = colors.fg;
              template = "  {{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }} ";
              properties = {
                display_mode = "files";
                fetch_version = true;
                min_width = 180;
              };
            }
            {
              type = "azfunc";
              style = "powerline";
              powerline_symbol = "";
              invert_powerline = true;
              background = colors.orange;
              foreground = colors.fg;
              template = "  {{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }} ";
              properties = {
                display_mode = "files";
                fetch_version = false;
                min_width = 190;
              };
            }
            {
              type = "aws";
              style = "powerline";
              powerline_symbol = "";
              invert_powerline = true;
              foreground = colors.fg;
              timeout = 500;
              background_templates = [
                "{{if contains \"default\" .Profile}}${colors.yellow}{{end}}"
                "{{if contains \"jan\" .Profile}}${colors.red}{{end}}"
              ];
              template = "  {{ .Profile }}{{ if .Region }}@{{ .Region }}{{ end }} ";
              properties = {
                display_default = false;
                min_width = 200;
              };
            }
            {
              type = "root";
              style = "powerline";
              powerline_symbol = "";
              invert_powerline = true;
              background = colors.yellow;
              foreground = colors.bg;
              template = "  ";
            }
            {
              type = "executiontime";
              style = "powerline";
              powerline_symbol = "";
              invert_powerline = true;
              background = colors.yellow;
              foreground = colors.bg;
              template = "  {{ .FormattedMs }} ";
            }
            {
              type = "exit";
              style = "powerline";
              powerline_symbol = "";
              invert_powerline = true;
              background = colors.bg_dark;
              foreground = colors.green;
              foreground_templates = [ "{{ if gt .Code 0 }}${colors.yellow}{{ end }}" ];
              background_templates = [ "{{ if gt .Code 0 }}${colors.red}{{ end }}" ];
              template = " {{ if gt .Code 0 }} {{ .Code }} {{ else }}✔ {{ end }}";
              properties = {
                always_enabled = true;
              };
            }
            {
              type = "time";
              style = "diamond";
              invert_powerline = true;
              background = colors.fg;
              foreground = colors.bg;
              template = "  {{ .CurrentDate | date .Format }} ";
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
              foreground = colors.comment;
              template = "╰─";
            }
          ];
        }
      ];
    };
  };
}
