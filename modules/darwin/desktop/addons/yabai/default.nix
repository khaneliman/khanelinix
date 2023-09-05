{ options
, config
, lib
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.desktop.addons.yabai;
  yabaiHelper =
    pkgs.writeShellScriptBin "yabaiHelper" (builtins.readFile ./helper);
in
{
  options.khanelinix.desktop.addons.yabai = {
    enable = mkBoolOpt false "Whether or not to enable yabai.";
  };

  config = mkIf cfg.enable {
    services.yabai = {
      enable = true;
      package = pkgs.yabai;
      enableScriptingAddition = true;

      config = {
        external_bar = "all:$${BAR_HEIGHT}:0";
        split_type = "auto";
        split_ratio = "0.5";
        auto_balance = "off";
        insert_feedback_color = "0xff7793d1";
        # external_bar all:39:0 \

        window_placement = "second_child";
        window_topmost = "on";
        window_shadow = "float";
        window_opacity = "on";
        active_window_opacity = "1.0";
        normal_window_opacity = "0.9";
        window_animation_duration = "0.0";
        window_origin_display = "focused";
        window_opacity_duration = "0.15";
        # window_topmost off \
        # normal_window_opacity 0.95 \
        # window_animation_duration 0.15

        window_border = "on";
        window_border_blur = "off";
        window_border_hidpi = "on";
        window_border_width = "2";
        window_border_radius = "12";
        active_window_border_color = "0xff7793d1";
        normal_window_border_color = "0xff5e6798";
        # window_border_radius 11 \

        layout = "bsp";
        top_padding = "20";
        bottom_padding = "10";
        left_padding = "10";
        right_padding = "10";
        window_gap = "10";

        mouse_modifier = "super";
        mouse_action1 = "move";
        mouse_action2 = "resize";
        mouse_drop_action = "swap";
        focus_follows_mouse = "autoraise";
        mouse_follows_focus = "off";
      };

      extraConfig = with pkgs; ''
        ${builtins.readFile ./extraConfig}

        source ${yabaiHelper}/bin/yabaiHelper

        # Signal hooks
        ${getExe yabai} -m signal --add event=dock_did_restart action="sudo ${getExe yabai} --load-sa"
        ${getExe yabai} -m signal --add event=window_focused action="${getExe sketchybar} --trigger window_focus"
        ${getExe yabai} -m signal --add event=display_added action="sleep 1 && source ${yabaiHelper}/bin/yabaiHelper && create_spaces 7"
        ${getExe yabai} -m signal --add event=display_removed action="sleep 1 && source ${yabaiHelper}/bin/yabaiHelper && create_spaces 7"
        ${getExe yabai} -m signal --add event=window_created action="${getExe sketchybar} --trigger windows_on_spaces"
        ${getExe yabai} -m signal --add event=window_destroyed action="${getExe sketchybar} --trigger windows_on_spaces"
        ${getExe yabai} -m signal --add event=window_created app="Code" action="source $HOME/.config/bin/helper && auto_stack Code"
        # ${getExe yabai} -m signal --add event=window_created app="Firefox" title!="(— Private Browsing$|^Picture-in-Picture$)" action="source ${yabaiHelper}/bin/yabaiHelper && auto_stack Firefox"
        # ${getExe yabai} -m signal --add event=window_title_changed app="Firefox" title="- noVNC$" action="${getExe yabai} -m window $WINDOW_ID --toggle native-fullscreen"

        echo "yabai configuration loaded.."
      '';
    };
  };
}
