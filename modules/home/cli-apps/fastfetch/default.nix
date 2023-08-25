{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.cli-apps.fastfetch;
  jsonFormat = pkgs.formats.json { };
  jsonconfig = {
    "$schema" = "https:#github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
    "logo" = {
      "padding" = {
        "top" = 2;
      };
    };
    "display" = {
      "color" = {
        "keys" = "green";
        "title" = "blue";
      };
      "percentType" = 9;
      "separator" = " 󰁔 ";
      "temperatureUnit" = "F";
    };
    "modules" = [
      {
        "type" = "custom";
        "key" = "┌──────────── OS Information ────────────┐";
        "keyColor" = "blue";
        "format" = " ";
      }
      {
        "type" = "title";
        "key" = " ╭─ ";
        "keyColor" = "green";
        "color" = {
          "user" = "green";
          "host" = "green";
        };
      }
    ] ++ lib.optionals pkgs.stdenv.isDarwin [
      {
        "type" = "os";
        "key" = " ├─  ";
        "keyColor" = "green";
      }
      {
        "type" = "kernel";
        "key" = " ├─  ";
        "keyColor" = "green";
      }
      {
        "type" = "packages";
        "key" = " ├─  ";
        "keyColor" = "green";
      }
    ] ++ lib.optionals pkgs.stdenv.isLinux [
      {
        "type" = "os";
        "key" = " ├─ ";
        "keyColor" = "green";
      }
      {
        "type" = "kernel";
        "key" = " ├─ ";
        "keyColor" = "green";
      }
      {
        "type" = "packages";
        "key" = " ├─ ";
        "keyColor" = "green";
      }
    ]
    ++ [
      {
        "type" = "shell";
        "key" = " ╰─  ";
        "keyColor" = "green";
      }
      {
        "type" = "custom";
        "key" = "├───────── Hardware Information ─────────┤";
        "keyColor" = "blue";
        "format" = " ";
      }
      {
        "type" = "display";
        "key" = " ╭─ 󰍹 ";
        "keyColor" = "blue";
      }
      {
        "type" = "cpu";
        "key" = " ├─ 󰍛 ";
        "keyColor" = "blue";
      }
      {
        "type" = "gpu";
        "key" = " ├─ 󰍛 ";
        "keyColor" = "blue";
      }
      {
        "type" = "memory";
        "key" = " ├─   ";
        "keyColor" = "blue";
      }
      {
        "type" = "disk";
        "key" = " ╰─ 󱛟 ";
        "keyColor" = "blue";
      }
      {
        "type" = "custom";
        "key" = "├───────── Software Information ─────────┤";
        "keyColor" = "blue";
        "format" = " ";
      }
      {
        "type" = "wm";
        "key" = " ╭─  ";
        "keyColor" = "yellow";
      }
      {
        "type" = "terminal";
        "key" = " ├─  ";
        "keyColor" = "yellow";
      }
      {
        "type" = "font";
        "key" = " ╰─  ";
        "keyColor" = "yellow";
      }
      {
        "type" = "custom";
        "key" = "└────────────────────────────────────────┘";
        "keyColor" = "blue";
        "format" = " ";
      }
      {
        "type" = "custom";
        "key" = "                               ";
        "format" = " ";
      }
      "break"
    ];
  };
in
{
  options.khanelinix.cli-apps.fastfetch = with types; {
    enable = mkBoolOpt false "Whether or not to enable fastfetch.";
    local-overrides = mkOpt str "" "Local overrides to add to configuration.";
  };

  config = mkIf cfg.enable {
    xdg.configFile = {
      "fastfetch/config.conf".source = ./config/config.conf;
      "fastfetch/config.jsonc".source = jsonFormat.generate "config.jsonc" jsonconfig;
    };
  };
}

