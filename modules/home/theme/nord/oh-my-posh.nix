{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf mkForce;
  cfg = config.khanelinix.theme.nord;
  nord = import ./colors.nix;
in
{
  config = mkIf cfg.enable {
    programs.oh-my-posh = {
      enable = true;
      settings = mkForce {
        blocks = [
          {
            alignment = "left";
            type = "prompt";
            segments = [
              {
                background = nord.palette.nord9.hex;
                foreground = nord.palette.nord1.hex;
                style = "diamond";
                leading_diamond = "";
                trailing_diamond = "";
                template = "{{ if .WSL }}WSL at {{ end }}{{ .Icon }} ";
                type = "os";
              }
              {
                background = nord.palette.nord4.hex;
                foreground = nord.palette.nord0.hex;
                powerline_symbol = "";
                style = "powerline";
                template = " <b>{{ .Path }}</b> ";
                type = "path";
                properties = {
                  style = "full";
                };
              }
              {
                background = nord.palette.nord3.hex;
                foreground = nord.palette.nord4.hex;
                powerline_symbol = "";
                style = "powerline";
                template = " {{ if .UpstreamURL }}{{ url .UpstreamURL }} {{ end }}";
                type = "git";
              }
              {
                background = nord.palette.nord3.hex;
                foreground = nord.palette.nord4.hex;
                powerline_symbol = "";
                style = "powerline";
                template = "{{ .HEAD }}{{ if .BranchStatus }} {{ .BranchStatus }}{{ end }}{{ if .Working.Changed }} <${nord.palette.nord13.hex}> {{ .Working.String }}</>{{ end }}{{ if and (.Working.Changed) (.Staging.Changed) }} |{{ end }}{{ if .Staging.Changed }} <${nord.palette.nord14.hex}> {{ .Staging.String }}</>{{ end }} ";
                type = "git";
              }
              {
                background = nord.palette.nord12.hex;
                foreground = nord.palette.nord1.hex;
                powerline_symbol = "";
                style = "powerline";
                template = " jj status ";
                type = "command";
                properties = {
                  command = "jj root > /dev/null && jj log -r @ -n 1 --no-graph -T 'branches \" \" change_id.shortest() \" \"' --ignore-working-copy";
                  shell = "bash";
                };
              }
            ];
          }
          {
            alignment = "right";
            type = "prompt";
            filler = "<${nord.palette.nord2.hex},transparent>.</>";
            segments = [
              {
                background = nord.palette.nord14.hex;
                foreground = nord.palette.nord1.hex;
                powerline_symbol = "";
                invert_powerline = true;
                style = "powerline";
                template = "  {{ if .PackageManagerIcon }}{{ .PackageManagerIcon }} {{ end }}{{ .Full }} ";
                type = "node";
              }
              {
                background = nord.palette.nord9.hex;
                foreground = nord.palette.nord1.hex;
                powerline_symbol = "";
                invert_powerline = true;
                style = "powerline";
                template = "  {{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }} ";
                type = "go";
              }
              {
                background = nord.palette.nord15.hex;
                foreground = nord.palette.nord1.hex;
                powerline_symbol = "";
                invert_powerline = true;
                style = "powerline";
                template = "  {{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }} ";
                type = "julia";
              }
              {
                background = nord.palette.nord13.hex;
                foreground = nord.palette.nord1.hex;
                powerline_symbol = "";
                invert_powerline = true;
                style = "powerline";
                template = "  {{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }} ";
                type = "python";
              }
              {
                background = nord.palette.nord11.hex;
                foreground = nord.palette.nord1.hex;
                powerline_symbol = "";
                invert_powerline = true;
                style = "powerline";
                template = "  {{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }} ";
                type = "ruby";
              }
              {
                background = nord.palette.nord9.hex;
                foreground = nord.palette.nord1.hex;
                powerline_symbol = "";
                invert_powerline = true;
                style = "powerline";
                template = " ﳆ {{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }} ";
                type = "azfunc";
              }
              {
                background = nord.palette.nord12.hex;
                foreground = nord.palette.nord1.hex;
                powerline_symbol = "";
                invert_powerline = true;
                style = "powerline";
                template = "  {{ .Profile }}{{ if .Region }}@{{ .Region }}{{ end }} ";
                type = "aws";
              }
              {
                background = nord.palette.nord13.hex;
                foreground = nord.palette.nord1.hex;
                powerline_symbol = "";
                invert_powerline = true;
                style = "powerline";
                template = "  ";
                type = "root";
              }
              {
                background = nord.palette.nord13.hex;
                foreground = nord.palette.nord1.hex;
                powerline_symbol = "";
                invert_powerline = true;
                style = "powerline";
                template = " took {{ .FormattedMs }} ";
                type = "executiontime";
                properties = {
                  threshold = 500;
                };
              }
              {
                background = nord.palette.nord11.hex;
                foreground = nord.palette.nord1.hex;
                powerline_symbol = "";
                invert_powerline = true;
                style = "powerline";
                template = " exit {{ .Code }} ";
                type = "status";
                properties = {
                  always_enabled = false;
                  color_icon = false;
                };
              }
              {
                background = nord.palette.nord9.hex;
                foreground = nord.palette.nord1.hex;
                invert_powerline = true;
                style = "diamond";
                template = " {{ .CurrentDate | date .Format }}  ";
                type = "time";
                properties = {
                  time_format = "15:04:05";
                };
              }
            ];
          }
          {
            alignment = "left";
            newline = true;
            type = "prompt";
            segments = [
              {
                background = "transparent";
                foreground = nord.palette.nord14.hex;
                style = "plain";
                template = "╰─";
                type = "text";
              }
            ];
          }
        ];
        version = 2;
      };
    };
  };
}
