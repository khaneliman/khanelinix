{
  config,
  lib,
  ...
}:
let
  cfg = config.khanelinix.theme.catppuccin;

  catppuccin = import (lib.getFile "modules/home/theme/catppuccin/colors.nix");
in
{
  config = lib.mkIf cfg.enable {
    programs.oh-my-posh.settings.blocks = lib.mkForce [
      {
        type = "prompt";
        alignment = "left";
        segments = [
          {
            type = "os";
            style = "diamond";
            background = catppuccin.colors.surface0.hex;
            foreground = catppuccin.colors.text.hex;
            leading_diamond = "<${catppuccin.colors.overlay0.hex},transparent>╭─</>";
            template = " {{ if .WSL }}WSL at {{ end }}{{.Icon}} ";
          }
          {
            type = "path";
            style = "powerline";
            powerline_symbol = "";
            background = catppuccin.colors.blue.hex;
            foreground = catppuccin.colors.base.hex;
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
            background = catppuccin.colors.green.hex;
            foreground = catppuccin.colors.base.hex;
            background_templates = [
              "{{ if or (.Working.Changed) (.Staging.Changed) }}${catppuccin.colors.yellow.hex}{{ end }}"
              "{{ if and (gt .Ahead 0) (gt .Behind 0) }}${catppuccin.colors.peach.hex}{{ end }}"
              "{{ if gt .Ahead 0 }}${catppuccin.colors.sky.hex}{{ end }}"
              "{{ if gt .Behind 0 }}${catppuccin.colors.green.hex}{{ end }}"
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
            background = catppuccin.colors.green.hex;
            foreground = catppuccin.colors.base.hex;
            # background_templates = [
            #   "{{ if or (.Working.Changed) (.Staging.Changed) }}${catppuccin.colors.yellow.hex}{{ end }}"
            #   "{{ if and (gt .Ahead 0) (gt .Behind 0) }}${catppuccin.colors.peach.hex}{{ end }}"
            #   "{{ if gt .Ahead 0 }}${catppuccin.colors.sky.hex}{{ end }}"
            #   "{{ if gt .Behind 0 }}${catppuccin.colors.green.hex}{{ end }}"
            # ];
            # template = " {{ .UpstreamIcon }}{{ .HEAD }}{{if .BranchStatus }} {{ .BranchStatus }}{{ end }}{{ if .Working.Changed }}  {{ .Working.String }}{{ end }}{{ if and (.Working.Changed) (.Staging.Changed) }} |{{ end }}{{ if .Staging.Changed }}  {{ .Staging.String }}{{ end }}{{ if gt .StashCount 0 }}  {{ .StashCount }}{{ end }} ";
            properties = {
              fetch_status = true;
            };
          }
        ];
      }
      {
        type = "prompt";
        alignment = "right";
        filler = "<${catppuccin.colors.surface1.hex},transparent>.</>";
        segments = [
          {
            type = "node";
            style = "powerline";
            powerline_symbol = "";
            invert_powerline = true;
            background = catppuccin.colors.green.hex;
            foreground = catppuccin.colors.text.hex;
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
            background = catppuccin.colors.sky.hex;
            foreground = catppuccin.colors.base.hex;
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
            background = catppuccin.colors.blue.hex;
            foreground = catppuccin.colors.base.hex;
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
            background = catppuccin.colors.yellow.hex;
            foreground = catppuccin.colors.base.hex;
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
            background = catppuccin.colors.red.hex;
            foreground = catppuccin.colors.text.hex;
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
            background = catppuccin.colors.peach.hex;
            foreground = catppuccin.colors.text.hex;
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
            foreground = catppuccin.colors.text.hex;
            background_templates = [
              "{{if contains \"default\" .Profile}}${catppuccin.colors.yellow.hex}{{end}}"
              "{{if contains \"jan\" .Profile}}${catppuccin.colors.red.hex}{{end}}"
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
            background = catppuccin.colors.yellow.hex;
            foreground = catppuccin.colors.base.hex;
            template = "  ";
          }
          {
            type = "executiontime";
            style = "powerline";
            powerline_symbol = "";
            invert_powerline = true;
            background = catppuccin.colors.yellow.hex;
            foreground = catppuccin.colors.base.hex;
            template = " {{ .FormattedMs }}  ";
          }
          {
            type = "exit";
            style = "powerline";
            powerline_symbol = "";
            invert_powerline = true;
            background = catppuccin.colors.surface0.hex;
            foreground = catppuccin.colors.green.hex;
            foreground_templates = [ "{{ if gt .Code 0 }}${catppuccin.colors.yellow.hex}{{ end }}" ];
            background_templates = [ "{{ if gt .Code 0 }}${catppuccin.colors.red.hex}{{ end }}" ];
            template = " {{ if gt .Code 0 }} {{ .Code }} {{ else }}✔ {{ end }}";
            properties = {
              always_enabled = true;
            };
          }
          {
            type = "time";
            style = "diamond";
            invert_powerline = true;
            background = catppuccin.colors.text.hex;
            foreground = catppuccin.colors.base.hex;
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
            foreground = catppuccin.colors.overlay0.hex;
            template = "╰─";
          }
        ];
      }

    ];
  };
}
