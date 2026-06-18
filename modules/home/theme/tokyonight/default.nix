{
  config,
  lib,
  options,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkDefault
    mkIf
    mkOption
    types
    ;

  cfg = config.khanelinix.theme.tokyonight;
  palette = import ./colors.nix;
  thunderbirdAddon = pkgs.stdenvNoCC.mkDerivation {
    pname = "thunderbird-addon-tokyo-night";
    version = "1.0.1";

    src = pkgs.fetchurl {
      url = "https://addons.thunderbird.net/thunderbird/downloads/file/1020993/tokyo_night-1.0.1-tb.xpi";
      sha256 = "sha256-Vi5Talz3rWjoKmgORNvUg3S+GCpq07IalCIZN1CmsSc=";
    };

    dontUnpack = true;

    installPhase = ''
      runHook preInstall

      install -D "$src" "$out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/{a1377b45-90f3-4570-a869-21554f7ddc9c}.xpi"

      runHook postInstall
    '';
  };

  stylixAvailable = options ? stylix;
in
{
  imports = [
    ./apps.nix
    ./gtk.nix
    ./oh-my-posh.nix
    ./qt.nix
    ./sway.nix
  ];

  options.khanelinix.theme.tokyonight = {
    enable = mkEnableOption "Tokyonight theme for applications";

    variant = mkOption {
      type = types.enum [
        "day"
        "night"
        "storm"
        "moon"
      ];
      default = "night";
      description = "Tokyonight theme variant to use.";
    };
  };

  config = mkIf cfg.enable (
    lib.mkMerge [
      {
        assertions = [
          {
            assertion = !config.khanelinix.theme.catppuccin.enable;
            message = "Tokyonight and Catppuccin themes cannot be enabled at the same time";
          }
          {
            assertion = !config.khanelinix.theme.nord.enable;
            message = "Tokyonight and Nord themes cannot be enabled at the same time";
          }
        ];

        khanelinix.theme = {
          wallpaper = {
            theme = mkDefault "tokyonight";
            primary = mkDefault "pacman_upscayl_realesrgan-x4plus_x2.png";
            secondary = mkDefault "game_upscayl_realesrgan-x4plus_x2.png";
            lock = mkDefault "tron_upscayl_realesrgan-x4plus_x2.png";
            list = mkDefault [
              "comic_upscayl_realesrgan-x4plus_x2.png"
              "controls_upscayl_realesrgan-x4plus_x2.png"
              "game_upscayl_realesrgan-x4plus_x2.png"
              "gamveover_upscayl_realesrgan-x4plus_x2.png"
              "heroes_upscayl_realesrgan-x4plus_x2.png"
              "invader_upscayl_realesrgan-x4plus_x2.png"
              "joystick_upscayl_realesrgan-x4plus_x2.png"
              "js_upscayl_realesrgan-x4plus_x2.png"
              "pacman3_upscayl_realesrgan-x4plus_x2.png"
              "pacman_upscayl_realesrgan-x4plus_x2.png"
              "smile_upscayl_realesrgan-x4plus_x2.png"
              "spookyjs_upscayl_realesrgan-x4plus_x2.png"
              "tron_upscayl_realesrgan-x4plus_x2.png"
              "tv_upscayl_realesrgan-x4plus_x2.png"
              "void_upscayl_realesrgan-x4plus_x2.png"
            ];
          };
          stylix = {
            enable = true;
            theme = "tokyo-night-dark";

            cursor = {
              name = "Bibata-Modern-Ice";
              package = pkgs.bibata-cursors;
              size = 32;
            };

            icon = {
              name = "Papirus-Dark";
              package = pkgs.papirus-icon-theme;
            };
          };
        };
        khanelinix.programs.graphical.browsers.firefox.extensions.extraPackages =
          mkIf config.khanelinix.programs.graphical.browsers.firefox.enable
            [ pkgs.firefox-addons.tokyo-night-v2 ];

        khanelinix.programs.graphical.apps.thunderbird.theme =
          let
            colors = palette.getVariant cfg.variant;
          in
          {
            enable = true;
            isDark = cfg.variant != "day";
            colors = {
              inherit (colors)
                bg
                fg
                ;
              surface = colors.bg_dark;
              surfaceAlt = colors.bg_highlight;
              accent = colors.blue;
              accentSoft = colors.cyan;
              accentFg = if cfg.variant == "day" then "#ffffff" else colors.fg;
              border = colors.blue7;
            };
          };

        programs.thunderbird.profiles.${config.khanelinix.user.name} =
          mkIf config.khanelinix.programs.graphical.apps.thunderbird.enable
            {
              extensions = [ thunderbirdAddon ];
              settings."extensions.autoDisableScopes" = 0;
            };

        home = {
          pointerCursor = mkIf pkgs.stdenv.hostPlatform.isLinux {
            inherit (config.khanelinix.theme.gtk.cursor) name package size;
          };

          sessionVariables = mkIf pkgs.stdenv.hostPlatform.isLinux {
            CURSOR_THEME = config.khanelinix.theme.gtk.cursor.name;
          };
        };
      }

      (lib.optionalAttrs stylixAvailable {
        stylix.image = lib.khanelinix.theme.wallpaperPath {
          inherit config pkgs;
          name = config.khanelinix.theme.wallpaper.primary;
        };
      })
    ]
  );
}
