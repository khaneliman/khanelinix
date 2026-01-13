{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.terminal.tools.fastfetch;
in
{
  options.khanelinix.programs.terminal.tools.fastfetch = {
    enable = lib.mkEnableOption "fastfetch";
  };

  config = mkIf cfg.enable {

    programs.fastfetch = {
      enable = true;
      package = pkgs.fastfetchMinimal;

      settings = {
        "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
        logo = {
          padding = {
            top = 2;
          };
        };
        display = {
          color = {
            keys = "green";
            title = "blue";
          };
          percent = {
            type = 9;
          };
          separator = " 󰁔 ";
        };
        modules = [
          {
            type = "custom";
            outputColor = "blue";
            format = "┌──────────── OS Information ────────────┐";
          }
          {
            type = "title";
            key = " ╭─ ";
            keyColor = "green";
            color = {
              user = "green";
              host = "green";
            };
          }
        ]
        ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
          {
            type = "os";
            key = " ├─  ";
            keyColor = "green";
          }
          {
            type = "kernel";
            key = " ├─  ";
            keyColor = "green";
          }
          {
            type = "packages";
            key = " ├─  ";
            keyColor = "green";
          }
        ]
        ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          {
            type = "os";
            key = " ├─ ";
            keyColor = "green";
          }
          {
            type = "kernel";
            key = " ├─ ";
            keyColor = "green";
          }
          {
            type = "packages";
            key = " ├─ ";
            keyColor = "green";
          }
        ]
        ++ [
          {
            type = "shell";
            key = " ╰─  ";
            keyColor = "green";
          }
          {
            type = "custom";
            outputColor = "blue";
            format = "├───────── Hardware Information ─────────┤";
          }
          {
            type = "display";
            key = " ╭─ 󰍹 ";
            keyColor = "blue";
            compactType = "original-with-refresh-rate";
          }
          {
            type = "cpu";
            key = " ├─ 󰍛 ";
            keyColor = "blue";
          }
          {
            type = "gpu";
            key = " ├─  ";
            keyColor = "blue";
          }
          {
            type = "disk";
            key = " ├─ 󱛟 ";
            keyColor = "blue";
          }
          {
            type = "memory";
            key = " ╰─  ";
            keyColor = "blue";
          }
          {
            type = "custom";
            outputColor = "blue";
            format = "├───────── Software Information ─────────┤";
          }
          {
            type = "wm";
            key = " ╭─  ";
            keyColor = "yellow";
          }
          {
            type = "terminal";
            key = " ├─  ";
            keyColor = "yellow";
          }
          {
            type = "font";
            key = " ╰─  ";
            keyColor = "yellow";
          }
          {
            type = "custom";
            outputColor = "blue";
            format = "└────────────────────────────────────────┘";
          }
          {
            type = "custom";
            format = "   {#39}   {#34}    {#36}    {#35}    {#34}    {#33}    {#32}    {#31} ";
          }
          "break"
        ];
      };
    };
  };
}
