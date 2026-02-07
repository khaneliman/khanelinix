{ config, lib }:
let
  catppuccin = import (lib.getFile "modules/home/theme/catppuccin/colors.nix");
  tokyonight = import (lib.getFile "modules/home/theme/tokyonight/colors.nix");
  nord = import (lib.getFile "modules/home/theme/nord/colors.nix");

  tokyonightColors = tokyonight.getVariant config.khanelinix.theme.tokyonight.variant;

  palette =
    if config.khanelinix.theme.tokyonight.enable then
      {
        base = tokyonightColors.bg;
        mantle = tokyonightColors.bg_dark;
        crust = tokyonightColors.bg_dark1;
        text = tokyonightColors.fg;
        subtext0 = tokyonightColors.fg_gutter;
        subtext1 = tokyonightColors.fg_dark;
        surface0 = tokyonightColors.bg_highlight;
        surface1 = tokyonightColors.dark3;
        surface2 = tokyonightColors.dark5;
        overlay0 = tokyonightColors.blue0;
        overlay1 = tokyonightColors.blue1;
        overlay2 = tokyonightColors.blue2;
        inherit (tokyonightColors) blue;
        lavender = tokyonightColors.purple;
        sapphire = tokyonightColors.blue6;
        sky = tokyonightColors.cyan;
        inherit (tokyonightColors) teal;
        inherit (tokyonightColors) green;
        inherit (tokyonightColors) yellow;
        peach = tokyonightColors.orange;
        maroon = tokyonightColors.red1;
        inherit (tokyonightColors) red;
        mauve = tokyonightColors.magenta;
        pink = tokyonightColors.magenta2;
        flamingo = tokyonightColors.red1;
        rosewater = tokyonightColors.blue7;
      }
    else if config.khanelinix.theme.nord.enable then
      {
        base = nord.palette.nord0.hex;
        mantle = nord.palette.nord1.hex;
        crust = nord.palette.nord0.hex;
        text = nord.palette.nord6.hex;
        subtext0 = nord.palette.nord5.hex;
        subtext1 = nord.palette.nord4.hex;
        surface0 = nord.palette.nord1.hex;
        surface1 = nord.palette.nord2.hex;
        surface2 = nord.palette.nord3.hex;
        overlay0 = nord.palette.nord3.hex;
        overlay1 = nord.palette.nord3.hex;
        overlay2 = nord.palette.nord3.hex;
        blue = nord.palette.nord10.hex;
        lavender = nord.palette.nord9.hex;
        sapphire = nord.palette.nord8.hex;
        sky = nord.palette.nord8.hex;
        teal = nord.palette.nord7.hex;
        green = nord.palette.nord14.hex;
        yellow = nord.palette.nord13.hex;
        peach = nord.palette.nord12.hex;
        maroon = nord.palette.nord11.hex;
        red = nord.palette.nord11.hex;
        mauve = nord.palette.nord15.hex;
        pink = nord.palette.nord15.hex;
        flamingo = nord.palette.nord12.hex;
        rosewater = nord.palette.nord6.hex;
      }
    else
      {
        base = catppuccin.colors.base.hex;
        mantle = catppuccin.colors.mantle.hex;
        crust = catppuccin.colors.crust.hex;
        text = catppuccin.colors.text.hex;
        subtext0 = catppuccin.colors.subtext0.hex;
        subtext1 = catppuccin.colors.subtext1.hex;
        surface0 = catppuccin.colors.surface0.hex;
        surface1 = catppuccin.colors.surface1.hex;
        surface2 = catppuccin.colors.surface2.hex;
        overlay0 = catppuccin.colors.overlay0.hex;
        overlay1 = catppuccin.colors.overlay1.hex;
        overlay2 = catppuccin.colors.overlay2.hex;
        blue = catppuccin.colors.blue.hex;
        lavender = catppuccin.colors.lavender.hex;
        sapphire = catppuccin.colors.sapphire.hex;
        sky = catppuccin.colors.sky.hex;
        teal = catppuccin.colors.teal.hex;
        green = catppuccin.colors.green.hex;
        yellow = catppuccin.colors.yellow.hex;
        peach = catppuccin.colors.peach.hex;
        maroon = catppuccin.colors.maroon.hex;
        red = catppuccin.colors.red.hex;
        mauve = catppuccin.colors.mauve.hex;
        pink = catppuccin.colors.pink.hex;
        flamingo = catppuccin.colors.flamingo.hex;
        rosewater = catppuccin.colors.rosewater.hex;
      };
in
{
  style = lib.mkDefault /* css */ ''
    @define-color base   ${palette.base};
    @define-color mantle ${palette.mantle};
    @define-color crust  ${palette.crust};

    @define-color text     ${palette.text};
    @define-color subtext0 ${palette.subtext0};
    @define-color subtext1 ${palette.subtext1};

    @define-color surface0 ${palette.surface0};
    @define-color surface1 ${palette.surface1};
    @define-color surface2 ${palette.surface2};

    @define-color overlay0 ${palette.overlay0};
    @define-color overlay1 ${palette.overlay1};
    @define-color overlay2 ${palette.overlay2};

    @define-color blue      ${palette.blue};
    @define-color lavender  ${palette.lavender};
    @define-color sapphire  ${palette.sapphire};
    @define-color sky       ${palette.sky};
    @define-color teal      ${palette.teal};
    @define-color green     ${palette.green};
    @define-color yellow    ${palette.yellow};
    @define-color peach     ${palette.peach};
    @define-color maroon    ${palette.maroon};
    @define-color red       ${palette.red};
    @define-color mauve     ${palette.mauve};
    @define-color pink      ${palette.pink};
    @define-color flamingo  ${palette.flamingo};
    @define-color rosewater ${palette.rosewater};

    @define-color noti-border-color @surface0;
    @define-color noti-close-bg @surface0;
    @define-color noti-close-bg-hover @surface1;
    @define-color noti-bg-hover alpha(@blue, 0.18);
    @define-color noti-bg-focus alpha(@blue, 0.3);
    @define-color noti-urgent #BF616A;

    @define-color bg-selected @blue;
    @define-color glass @surface0;
    @define-color glass-strong @surface1;
    @define-color panel-border @surface0;
    @define-color panel-border-strong @surface1;

    * {
      color: @text;
      font-family: "Iosevka Aile", "Iosevka", "JetBrains Mono", monospace;
    }

    .notification-row {
      outline: none;
    }

    .notification-row:focus,
    .notification-row:hover {
      background: transparent;
    }

    .notification {
      background: linear-gradient(180deg, @base, @mantle);
      background-color: @base;
      border-radius: 14px;
      border: 1px solid alpha(@blue, 0.4);
      margin: 8px 12px;
      box-shadow: 0 0 0 1px alpha(@overlay2, 0.28), 0 16px 36px rgba(0, 0, 0, 0.6),
        inset 0 1px 0 alpha(@overlay2, 0.3);
      padding: 0;
      transition: background 0.15s ease, border-color 0.15s ease, transform 0.15s ease;
    }

    .notification-row:hover .notification {
      background: linear-gradient(180deg, @mantle, @base);
      background-color: @base;
      border-color: alpha(@blue, 0.55);
      box-shadow: 0 0 0 1px alpha(@blue, 0.45), 0 18px 40px rgba(0, 0, 0, 0.65),
        inset 0 1px 0 alpha(@overlay2, 0.36);
      transform: translateY(-1px);
    }

    /* Uncomment to enable specific urgency colors */
    /* .low {
      background: yellow;
      padding: 6px;
      border-radius: 12px;
    }
    .normal {
      background: green;
      padding: 6px;
      border: 2px solid @surface1;
    } */

    .critical {
      background: alpha(@red, 0.18);
      border-left: 3px solid @red;
      padding: 2px;
    }

    .notification-content {
      background: transparent;
      padding: 10px;
    }

    .close-button {
      background: @glass;
      color: @text;
      text-shadow: none;
      padding: 0;
      border-radius: 999px;
      margin-top: 8px;
      margin-right: 12px;
      box-shadow: none;
      border: 1px solid @panel-border;
      min-width: 26px;
      min-height: 26px;
    }

    .close-button:hover {
      box-shadow: none;
      background: @noti-close-bg-hover;
      transition: all 0.15s ease-in-out;
      border: 1px solid @glass-strong;
    }

    .notification-default-action,
    .notification-action {
      padding: 6px;
      margin: 0;
      box-shadow: none;
      color: @text;
    }

    .notification-default-action {
      background: transparent;
      border: none;
    }

    .notification-default-action:hover {
      -gtk-icon-effect: none;
      background: linear-gradient(90deg, alpha(@blue, 0.18), alpha(@sky, 0.1));
    }

    .notification-action {
      background: alpha(@surface1, 0.9);
      border: 1px solid @panel-border-strong;
    }

    .notification-action:hover {
      -gtk-icon-effect: none;
      background: linear-gradient(90deg, alpha(@blue, 0.28), alpha(@sky, 0.18));
    }

    .notification-default-action {
      border-radius: 12px;
    }

    /* When alternative actions are visible */
    .notification-default-action:not(:only-child) {
      border-bottom-left-radius: 0px;
      border-bottom-right-radius: 0px;
    }

    .notification-action {
      border-radius: 0px;
      border-top: none;
      border-right: none;
    }

    /* add bottom border radius to eliminate clipping */
    .notification-action:first-child {
      border-bottom-left-radius: 10px;
    }

    .notification-action:last-child {
      border-bottom-right-radius: 10px;
      border-right: 1px solid @noti-border-color;
    }

    .image {
    }

    .body-image {
      margin-top: 6px;
      background-color: @crust;
      border-radius: 14px;
    }

    .summary {
      font-size: 15px;
      font-weight: 700;
      background: transparent;
      color: @text;
      text-shadow: 0 1px 0 rgba(0, 0, 0, 0.35);
    }

    .time {
      font-size: 13px;
      font-weight: 600;
      background: transparent;
      color: @subtext1;
      text-shadow: 0 1px 0 rgba(0, 0, 0, 0.3);
      margin-right: 14px;
    }

    .body {
      font-size: 14px;
      font-weight: normal;
      background: transparent;
      color: @subtext1;
      text-shadow: 0 1px 0 rgba(0, 0, 0, 0.25);
    }

    /* The "Notifications" and "Do Not Disturb" text widget */
    .top-action-title {
      color: @subtext0;
      text-shadow: none;
    }

    .control-center {
      background: linear-gradient(180deg, @base, @mantle);
      border: 1px solid @panel-border-strong;
      border-radius: 18px;
      box-shadow: 0 20px 48px rgba(0, 0, 0, 0.55), inset 0 1px 0 alpha(@overlay2, 0.2);
      padding: 6px 0 10px 0;
    }

    .control-center-list {
      background: transparent;
    }

    .floating-notifications {
      background: transparent;
    }

    /* Window behind control center and on all other monitors */
    .blank-window {
      background: transparent;
    }

    /*** Widgets ***/

    /* Title widget */
    .widget-title {
      margin: 10px 12px 6px 12px;
      font-size: 1.4rem;
    }

    .widget-title > button {
      font-size: initial;
      color: @text;
      text-shadow: none;
      background: alpha(@surface0, 0.9);
      border: 1px solid @panel-border-strong;
      box-shadow: none;
      border-radius: 10px;
    }

    .widget-title > button:hover {
      background: linear-gradient(90deg, alpha(@blue, 0.22), alpha(@sky, 0.14));
      border-color: @panel-border-strong;
    }

    /* DND widget */
    .widget-dnd {
      margin: 6px 12px 12px 12px;
      font-size: 1.05rem;
    }

    .widget-dnd > switch {
      font-size: initial;
      border-radius: 999px;
      background: alpha(@surface0, 0.9);
      border: 1px solid @panel-border-strong;
      box-shadow: none;
    }

    .widget-dnd > switch:checked {
      background: @bg-selected;
    }

    .widget-dnd > switch slider {
      background: @text;
      border-radius: 999px;
    }

    /* Label widget */
    .widget-label {
      margin: 12px 12px 6px 12px;
    }

    .widget-label > label {
      font-size: 1.45rem;
      font-weight: 700;
      letter-spacing: 0.02em;
    }

    /* Mpris widget */
    .widget-mpris {
      /* The parent to all players */
    }

    .widget-mpris-player {
      background: @mantle;
      border: 1px solid @panel-border-strong;
      border-radius: 14px;
      padding: 10px;
      margin: 10px 12px 12px 12px;
    }

    .widget-mpris-title {
      font-weight: 600;
      font-size: 1.15rem;
    }

    .widget-mpris-subtitle {
      font-size: 1rem;
      color: @subtext0;
    }

    /* Volume and Brightness Widget*/

    .widget-volume {
      background-color: @mantle;
      padding: 8px 10px 10px 10px;
      margin: 0px 12px 12px 12px;
      border-radius: 14px;
      border: 1px solid @panel-border-strong;
    }

    .widget-backlight {
      background-color: @mantle;
      padding: 10px 10px 8px 10px;
      margin: 12px 12px 0px 12px;
      border-radius: 14px;
      border: 1px solid @panel-border-strong;
    }

    .KB {
      padding: 6px 10px 8px 10px;
      margin: 0px 12px 0px 12px;
      border-radius: 0;
    }

    .power-buttons {
      background-color: @mantle;
      padding: 8px;
      margin: 8px 12px;
      border-radius: 14px;
      border: 1px solid @panel-border-strong;
    }

    .power-buttons > button {
      background: transparent;
      border: none;
    }

    .power-buttons > button:hover {
      background: linear-gradient(90deg, alpha(@blue, 0.22), alpha(@sky, 0.14));
    }


    .widget-menubar {
      border: none;
      background: @mantle;
      margin: 0 12px 8px 12px;
      padding: 10px;
      border-radius: 14px;
      border: 1px solid @panel-border-strong;
    }

    .widget-menubar > box > .menu-button-bar > button {
      border: none;
      background: transparent;
    }

    .screenshot-buttons > button {
      border: none;
      background: transparent;
    }

    .widget-buttons-grid {
      padding: 10px;
      margin: 8px 12px;
      border-radius: 14px;
      background-color: @mantle;
      border: 1px solid @panel-border-strong;
    }

    .widget-buttons-grid > flowbox > flowboxchild > button {
      background: alpha(@base, 0.88);
      border-radius: 12px;
      border: 1px solid @panel-border-strong;
    }

    .widget-buttons-grid > flowbox > flowboxchild > button:hover {
      background: linear-gradient(90deg, alpha(@blue, 0.2), alpha(@sky, 0.12));
      border-color: @panel-border-strong;
    }

    .powermode-buttons, .screenshot-buttons {
      background-color: @mantle;
      padding: 8px;
      margin: 8px 12px;
      border-radius: 14px;
      border: 1px solid @panel-border-strong;
    }

    .powermode-buttons > button {
      background: transparent;
      border: none;
    }

    .powermode-buttons > button:hover {
      background: linear-gradient(90deg, alpha(@blue, 0.22), alpha(@sky, 0.14));
    }

    .powermode-buttons > button:active {
      background: linear-gradient(90deg, alpha(@blue, 0.3), alpha(@sky, 0.2));
    }

    .screenshot-buttons > button {
      background: transparent;
      border: none;
    }

    .screenshot-buttons > button:hover {
      background: linear-gradient(90deg, alpha(@blue, 0.22), alpha(@sky, 0.14));
    }

    scale trough {
      background: alpha(@surface2, 0.55);
      border-radius: 999px;
      min-height: 6px;
    }

    scale trough highlight {
      background: linear-gradient(90deg, alpha(@sky, 0.95), alpha(@blue, 0.95));
      border-radius: 999px;
    }

    scale slider {
      background: @text;
      border-radius: 999px;
      min-width: 14px;
      min-height: 14px;
      box-shadow: 0 0 0 2px alpha(@base, 0.75), 0 2px 6px rgba(0, 0, 0, 0.4);
    }
  '';
}
