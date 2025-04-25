{ lib }:
{
  style =
    lib.mkDefault # css
      ''
        /*
        *
        * Catppuccin Macchiato palette
        *
        */

        @define-color base   #24273a;
        @define-color mantle #1e2030;
        @define-color crust  #181926;

        @define-color text     #cad3f5;
        @define-color subtext0 #b8c0e0;
        @define-color subtext1 #a5adcb;

        @define-color surface0 #363a4f;
        @define-color surface1 #494d64;
        @define-color surface2 #5b6078;

        @define-color overlay0 #6e738d;
        @define-color overlay1 #8087a2;
        @define-color overlay2 #939ab7;

        @define-color blue      #8aadf4;
        @define-color lavender  #b7bdf8;
        @define-color sapphire  #7dc4e4;
        @define-color sky       #91d7e3;
        @define-color teal      #8bd5ca;
        @define-color green     #a6da95;
        @define-color yellow    #eed49f;
        @define-color peach     #f5a97f;
        @define-color maroon    #ee99a0;
        @define-color red       #ed8796;
        @define-color mauve     #c6a0f6;
        @define-color pink      #f5bde6;
        @define-color flamingo  #f0c6c6;
        @define-color rosewater #f4dbd6;

        @define-color noti-border-color rgba(255, 255, 255, 0.9);
        @define-color noti-close-bg rgba(255, 255, 255, 0.1);
        @define-color noti-close-bg-hover rgba(255, 255, 255, 0.15);
        @define-color noti-bg-hover @blue;
        @define-color noti-bg-focus @green;
        @define-color noti-urgent #BF616A;

        @define-color bg-selected rgb(0, 128, 255);

        * {
          color: @text;
        }

        .notification-row {
          outline: none;
        }

        .notification-row:focus,
        .notification-row:hover {
          background: @noti-bg-focus;
        }

        .notification {
          border-radius: 0.5em;
          margin: 6px 12px;
          box-shadow: 0 0 0 1px rgba(255, 255, 255, 0.3),
            0 1px 3px 1px rgba(0, 0, 0, 0.7), 0 2px 6px 2px rgba(0, 0, 0, 0.3);
          padding: 0;
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
          background: @noti-urgent;
          padding: 2px;
        }

        .notification-content {
          background: transparent;
          padding: 6px;
        }

        .close-button {
          background: @noti-close-bg;
          color: white;
          text-shadow: none;
          padding: 0;
          border-radius: 1em;
          margin-top: 10px;
          margin-right: 16px;
          box-shadow: none;
          border: none;
          min-width: 24px;
          min-height: 24px;
        }

        .close-button:hover {
          box-shadow: none;
          background: @noti-close-bg-hover;
          transition: all 0.15s ease-in-out;
          border: none;
        }

        .notification-default-action,
        .notification-action {
          padding: 4px;
          margin: 0;
          box-shadow: none;
          background: @mantle;
          border: none;
          color: white;
        }

        .notification-default-action:hover,
        .notification-action:hover {
          -gtk-icon-effect: none;
          background: @noti-bg-hover;
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
          background-color: white;
          border-radius: 12px;
        }

        .summary {
          font-size: 16px;
          font-weight: bold;
          background: transparent;
          color: white;
          text-shadow: none;
        }

        .time {
          font-size: 16px;
          font-weight: bold;
          background: transparent;
          color: white;
          text-shadow: none;
          margin-right: 18px;
        }

        .body {
          font-size: 15px;
          font-weight: normal;
          background: transparent;
          color: white;
          text-shadow: none;
        }

        /* The "Notifications" and "Do Not Disturb" text widget */
        .top-action-title {
          color: white;
          text-shadow: none;
        }

        .control-center {
          /* background: alpha(@base, .97); */
          background-color: @base;
          border: 2px solid @surface1;
          border-radius: 1em;
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
          margin: 8px;
          font-size: 1.5rem;
        }

        .widget-title > button {
          font-size: initial;
          color: white;
          text-shadow: none;
          background: @mantle;
          border: 1px solid @noti-border-color;
          box-shadow: none;
          border-radius: 12px;
        }

        .widget-title > button:hover {
          background: @noti-bg-hover;
        }

        /* DND widget */
        .widget-dnd {
          margin: 8px;
          font-size: 1.1rem;
        }

        .widget-dnd > switch {
          font-size: initial;
          border-radius: 12px;
          background: @mantle;
          border: 1px solid @noti-border-color;
          box-shadow: none;
        }

        .widget-dnd > switch:checked {
          background: @bg-selected;
        }

        .widget-dnd > switch slider {
          background: @noti-bg-hover;
          border-radius: 12px;
        }

        /* Label widget */
        .widget-label {
          margin: 8px;
        }

        .widget-label > label {
          font-size: 1.5rem;
        }

        /* Mpris widget */
        .widget-mpris {
          /* The parent to all players */
        }

        .widget-mpris-player {
          padding: 8px;
          margin: 8px;
        }

        .widget-mpris-title {
          font-weight: bold;
          font-size: 1.25rem;
        }

        .widget-mpris-subtitle {
          font-size: 1.1rem;
        }

        /* Volume and Brightness Widget*/

        .widget-volume {
          background-color: @mantle;
          padding: 4px 8px 8px 8px;
          margin: 0px 8px 8px 8px;
          border-bottom-left-radius: 12px;
          border-bottom-right-radius: 12px;
        }

        .widget-backlight {
          background-color: @mantle;
          padding: 8px 8px 4px 8px;
          margin: 8px 8px 0px 8px;
          border-top-left-radius: 12px;
          border-top-right-radius: 12px;
        }

        .KB {
          padding: 4px 8px 4px 8px;
          margin: 0px 8px 0px 8px;
          border-radius: 0;
        }

        .power-buttons {
          background-color: @mantle;
          padding: 8px;
          margin: 8px;
          border-radius: 12px;
        }

        .power-buttons > button {
          background: transparent;
          border: none;
        }

        .power-buttons > button:hover {
          background: @noti-bg-hover;
        }


        .widget-menubar {
          border: none;
          background: transparent;
          margin: 0 8px 0 8px;
          padding: 8px;
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
          padding: 8px;
          margin: 8px;
          border-radius: 12px;
          background-color: @mantle;
        }

        .widget-buttons-grid > flowbox > flowboxchild > button {
          background: @base;
          border-radius: 12px;
        }

        .widget-buttons-grid > flowbox > flowboxchild > button:hover {
          background: @noti-bg-hover;
        }

        .powermode-buttons, .screenshot-buttons {
          background-color: @mantle;
          padding: 8px;
          margin: 8px;
          border-radius: 12px;
        }

        .powermode-buttons > button {
          background: transparent;
          border: none;
        }

        .powermode-buttons > button:hover {
          background: @noti-bg-hover;
        }

        .powermode-buttons > button:active {
          background: @noti-bg-hover;
        }

        .screenshot-buttons > button {
          background: transparent;
          border: none;
        }

        .screenshot-buttons > button:hover {
          background: @noti-bg-hover;
        }
      '';
}
