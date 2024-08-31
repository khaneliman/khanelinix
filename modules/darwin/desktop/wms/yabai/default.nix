{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) getExe;
  inherit (lib.${namespace}) mkBoolOpt enabled;

  cfg = config.${namespace}.desktop.wms.yabai;
in
{
  options.${namespace}.desktop.wms.yabai = {
    enable = mkBoolOpt false "Whether or not to enable yabai.";
    debug = mkBoolOpt false "Whether to enable debug output.";
  };

  config = lib.mkIf cfg.enable {
    ${namespace}.desktop.addons.jankyborders = enabled;

    services.yabai = {
      enable = true;
      package = pkgs.yabai;
      enableScriptingAddition = true;

      config = {
        debug_output = if cfg.debug then "on" else "off";
        # external_bar = "all:$${BAR_HEIGHT}:0";
        split_type = "auto";
        split_ratio = "0.5";
        auto_balance = "off";
        insert_feedback_color = "0xff7793d1";
        menubar_opacity = "0.5";

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

      extraConfig =
        let
          inherit (pkgs) sketchybar;
        in
        # bash
        ''
          source ${getExe pkgs.${namespace}.yabai-helper}

          # Set external_bar here in case we launch after sketchybar
          BAR_HEIGHT=$(${getExe sketchybar} -m --query bar | jq -r '.height')
          ${getExe config.services.yabai.package} -m config external_bar all:"$BAR_HEIGHT":0

          ${builtins.readFile ./extraConfig}

          # Signal hooks
          ${getExe config.services.yabai.package} -m signal --add event=dock_did_restart action="sudo ${getExe config.services.yabai.package} --load-sa"
          ${getExe config.services.yabai.package} -m signal --add event=window_focused action="${getExe sketchybar} --trigger window_focus"
          ${getExe config.services.yabai.package} -m signal --add event=display_added action="sleep 1 && source ${
            getExe pkgs.${namespace}.yabai-helper
          } && create_spaces 7"
          ${getExe config.services.yabai.package} -m signal --add event=display_removed action="sleep 1 && source ${
            getExe pkgs.${namespace}.yabai-helper
          } && create_spaces 7"
          ${getExe config.services.yabai.package} -m signal --add event=window_created action="${getExe sketchybar} --trigger windows_on_spaces"
          ${getExe config.services.yabai.package} -m signal --add event=window_destroyed action="${getExe sketchybar} --trigger windows_on_spaces"
          ${getExe config.services.yabai.package} -m signal --add event=window_created app="Code" action="source ${
            getExe pkgs.${namespace}.yabai-helper
          } && auto_stack Code"
          # ${getExe config.services.yabai.package} -m signal --add event=window_created app="Firefox" title!="(— Private Browsing$|^Picture-in-Picture$)" action="source ${
            getExe pkgs.${namespace}.yabai-helper
          } && auto_stack Firefox"
          # ${getExe config.services.yabai.package} -m signal --add event=window_title_changed app="Firefox" title="- noVNC$" action="${getExe config.services.yabai.package} -m window $WINDOW_ID --toggle native-fullscreen"

          # jankyborders
          ${getExe config.${namespace}.desktop.addons.jankyborders.package} 2>/dev/null 1>&2 &

          echo "yabai configuration loaded.."
        '';
    };
  };
}
