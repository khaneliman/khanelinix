{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf mkEnableOption mkOption types;
  inherit (lib.internal) mkOpt;

  cfg = config.khanelinix.desktop.theme;

  catppuccinAccents = [ "rosewater" "flamingo" "pink" "mauve" "red" "maroon" "peach" "yellow" "green" "teal" "sky" "sapphire" "blue" "lavender" ];
  catppuccinVariants = [ "latte" "frappe" "macchiato" "mocha" ];

  fromYAML = f:
    let
      jsonFile =
        pkgs.runCommand "yaml to attribute set"
          {
            nativeBuildInputs = [ pkgs.jc ];
          } ''
          jc --yaml < "${f}" > "$out"
        '';
    in
    builtins.elemAt (builtins.fromJSON (builtins.readFile jsonFile)) 0;
in
{
  options.khanelinix.desktop.theme = {
    enable = mkEnableOption "Enable custom theme use for applications.";
    selectedTheme = mkOption {
      type = types.submodule {
        options = {
          name = mkOpt types.str "catppuccin" "The theme to use.";
          accent = mkOption {
            type = types.enum catppuccinAccents;
            default = "blue";
            description = ''
              An optional theme accent.
            '';
          };
          variant = mkOption {
            type = types.enum catppuccinVariants;
            default = "macchiato";
            description = ''
              An optional theme variant.
            '';
          };
        };
      };
      default = {
        name = "catppuccin";
        accent = "blue";
        variant = "macchiato";
      };
      description = "Theme to use for applications.";
    };
    package = mkOption {
      type = types.package;
      default = pkgs.catppuccin.override {
        inherit (cfg.selectedTheme) accent;
        inherit (cfg.selectedTheme) variant;
      };
      description = ''
        The `spotifyd` package to use.
        Can be used to specify extensions.
      '';
    };
  };

  config = mkIf cfg.enable {
    programs = {
      bat = {
        config.theme = "${cfg.selectedTheme.name}-${cfg.selectedTheme.variant}";

        themes = {
          "${cfg.selectedTheme.name}-${cfg.selectedTheme.variant}" = {
            src = cfg.package;
            file = "/bat/Catppuccin-${cfg.selectedTheme.variant}.tmTheme";
          };
        };
      };

      git.delta = {
        options = {
          syntax-theme = mkIf config.khanelinix.tools.bat.enable "${cfg.selectedTheme.name}-${cfg.selectedTheme.variant}";
        };
      };

      bottom = {
        settings = builtins.fromTOML (builtins.readFile (cfg.package + "/bottom/${cfg.selectedTheme.variant}.toml"));
      };

      btop = {
        settings.color_theme = "${cfg.selectedTheme.name}_${cfg.selectedTheme.variant}";
      };

      k9s.skin = fromYAML (cfg.package + "/k9s/${cfg.selectedTheme.variant}.yml");

      tmux.plugins = [{
        plugin = pkgs.tmuxPlugins.catppuccin;
        extraConfig = ''
          set -g @catppuccin_flavour '${cfg.selectedTheme.variant}'
          set -g @catppuccin_host 'on'
          set -g @catppuccin_user 'on'
        '';
      }];
    };

    xdg.configFile = {
      "btop/themes/${cfg.selectedTheme.name}_${cfg.selectedTheme.variant}.theme" = {
        source = mkIf config.programs.btop.enable (cfg.package + "/btop/${cfg.selectedTheme.name}_${cfg.selectedTheme.variant}.theme");
      };
    };
  };
}
