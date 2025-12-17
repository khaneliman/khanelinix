{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) getExe;
  inherit (lib.khanelinix) mkOpt;

  cfg = config.khanelinix.desktop.wms.yabai;
  hmCfg = config.home-manager.users.${config.khanelinix.user.name};
in
{
  options.khanelinix.desktop.wms.yabai = {
    enable = lib.mkEnableOption "yabai";
    debug = lib.mkEnableOption "debug output";
    logFile = mkOpt lib.types.str "${
      config.users.users.${config.khanelinix.user.name}.home
    }/Library/Logs/yabai.log" "Filepath of log output";
  };

  config = lib.mkIf cfg.enable {
    khanelinix = {

      home.extraOptions = {
        home.shellAliases = {
          restart-yabai = ''launchctl kickstart -k gui/"$(id -u)"/org.nixos.yabai'';
        };
      };
    };

    launchd.user.agents.yabai.serviceConfig = {
      StandardErrorPath = cfg.logFile;
      StandardOutPath = cfg.logFile;
      KeepAlive = lib.mkForce {
        PathState = {
          "/run/current-system/sw/bin/yabai" = true;
        };
      };
    };

    services.yabai = {
      enable = true;
      package = pkgs.yabai;
      # NOTE: You need to disable SIP and set nvram boot args for this.
      # csrutil disable
      # sudo nvram boot-args=-arm64e_preview_abi
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

        # ['cmd|alt|shift|ctrl|fn']
        mouse_modifier = "cmd";
        mouse_action1 = "move";
        mouse_action2 = "resize";
        mouse_drop_action = "swap";
        focus_follows_mouse = "autoraise";
        mouse_follows_focus = "off";
      };

      extraConfig =
        let
          sketchybar =
            if hmCfg.programs.sketchybar.enable or false then
              lib.attrByPath [ "programs" "sketchybar" "finalPackage" ] pkgs.sketchybar hmCfg
            else
              pkgs.sketchybar;
          inherit (pkgs.khanelinix) yabai-helper;
        in
        /* Bash */ ''
          source ${getExe yabai-helper}

          # Set external_bar here in case we launch after sketchybar
          BAR_HEIGHT=$(${getExe sketchybar} -m --query bar | jq -r '.height')
          yabai -m config external_bar all:"$BAR_HEIGHT":0

          ${builtins.readFile ./extraConfig}

          # Signal hooks
          yabai -m signal --add event=dock_did_restart action="sudo yabai --load-sa"
          yabai -m signal --add event=window_focused action="${getExe sketchybar} --trigger window_focus"
          yabai -m signal --add event=display_added action="sleep 1 && source ${getExe yabai-helper} && create_spaces 7"
          yabai -m signal --add event=display_removed action="sleep 1 && source ${getExe yabai-helper} && create_spaces 7"
          yabai -m signal --add event=window_created action="${getExe sketchybar} --trigger windows_on_spaces"
          yabai -m signal --add event=window_destroyed action="${getExe sketchybar} --trigger windows_on_spaces"
          yabai -m signal --add event=window_created app="Code" action="source ${getExe yabai-helper} && auto_stack Code"
          # yabai -m signal --add event=window_created app="Firefox" title!="(— Private Browsing$|^Picture-in-Picture$)" action="source ${getExe yabai-helper} && auto_stack Firefox"
          # yabai -m signal --add event=window_title_changed app="Firefox" title="- noVNC$" action="yabai -m window $WINDOW_ID --toggle native-fullscreen"

          if ! pgrep "Raycast"; then
            open -a Raycast
          fi
          if ! pgrep "Amphetamine"; then
            open -a Amphetamine
          fi

          echo "yabai configuration loaded.."
        '';
    };
  };
}
