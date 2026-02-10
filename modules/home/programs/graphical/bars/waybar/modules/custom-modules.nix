{
  config,
  lib,
  osConfig ? { },
  pkgs,

  ...
}:
let
  inherit (lib) getExe getExe';

  enabledDmenuLaunchers =
    let
      inherit (config.khanelinix.programs.graphical) launchers;
    in
    lib.flatten [
      (lib.optional launchers.vicinae.enable "vicinae dmenu")
      (lib.optional launchers.anyrun.enable "anyrun --show-results-immediately true")
      (lib.optional launchers.walker.enable "walker --stream")
      (lib.optional launchers.sherlock.enable "sherlock")
      (lib.optional launchers.rofi.enable "rofi -dmenu")
    ];

  dmenuCommand = builtins.head enabledDmenuLaunchers;

  githubHelper = pkgs.writeShellScriptBin "githubHelper" ''
    ${lib.optionalString (osConfig.khanelinix.security.sops.enable or false) ''
      ${getExe pkgs.gh} auth login --with-token < ${config.sops.secrets."github/access-token".path}
    ''}

    # Get notifications and format them for the tooltip
    NOTIFICATIONS="$(${getExe pkgs.gh} api notifications)"
    COUNT=$(echo "$NOTIFICATIONS" | ${getExe pkgs.jq} 'length')

    if [ "$COUNT" -eq 0 ]; then
      echo '{"text":"0","tooltip":"No notifications","class":""}'
      exit 0
    fi

    # Format notifications into a tooltip with HTML
    TOOLTIP=$(echo "$NOTIFICATIONS" | ${getExe pkgs.jq} -r '
      def escape_html:
        gsub("&";"&amp;") | gsub("<";"&lt;") | gsub(">";"&gt;") | gsub("\"";"&quot;");

      def get_icon:
        if .subject.type == "Issue" then ""
        elif .subject.type == "Discussion" then "󰙯"
        elif .subject.type == "PullRequest" then ""
        elif .subject.type == "Commit" then ""
        else ""
        end;

      def repo_name:
        .repository.full_name // .repository.name // "Unknown";

      def indent:
        "  ";

      def notification_line:
        indent + "<span color=\"#565f89\">" + (get_icon | escape_html) + "</span> " +
        ((.subject.title // "Untitled") | escape_html);

      sort_by(repo_name, (.subject.title // ""))
      | group_by(repo_name)
      | map(
        "<span color=\"#7aa2f7\"><b>󰳏 " + ((.[0] | repo_name) | escape_html) + "</b></span>\n" +
        (map(notification_line) | join("\n"))
      )
      | join("\n\n")
    ' | sed 's/api.github.com\/repos/github.com/g' | sed 's/\/pulls\//\/pull\//g' | sed 's/\/commits\//\/commit\//g')

    echo "{\"text\":\"$COUNT\",\"tooltip\":$(echo "$TOOLTIP" | jq -R -s .),\"class\":\"has-notifications\"}"
  '';

  githubMenuHelper = pkgs.writeShellScriptBin "waybar-github-menu" ''
    ${lib.optionalString (osConfig.khanelinix.security.sops.enable or false) ''
      ${getExe pkgs.gh} auth login --with-token < ${config.sops.secrets."github/access-token".path}
    ''}

    NOTIFICATIONS_JSON=$(${getExe pkgs.gh} api notifications 2>/dev/null)

    if [ -z "$NOTIFICATIONS_JSON" ] || [ "$NOTIFICATIONS_JSON" = "[]" ]; then
      echo "No notifications" | ${dmenuCommand} -p "GitHub Notifications"
      exit 0
    fi

    # Format for dmenu: grouped by repo with icon + title entries.
    MENU_ENTRIES=$(echo "$NOTIFICATIONS_JSON" | ${getExe pkgs.jq} -r '
      def repo_name:
        .repository.full_name // .repository.name // "Unknown";

      def indent:
        "  ";

      def get_icon:
        if .subject.type == "Issue" then ""
        elif .subject.type == "Discussion" then "󰙯"
        elif .subject.type == "PullRequest" then ""
        elif .subject.type == "Commit" then ""
        else ""
        end;

      sort_by(repo_name, (.subject.title // ""))
      | group_by(repo_name)
      | map(
        map(indent + "\(repo_name): \(get_icon) \(.subject.title // "Untitled")")
        | join("\n")
      )
      | join("\n\n")
    ')
    SELECTED=$(echo "$MENU_ENTRIES" | ${dmenuCommand} -p "GitHub Notifications")
    SELECTED_NORMALIZED=$(echo "$SELECTED" | ${getExe pkgs.gnused} 's/^ *//')

    if [ -n "$SELECTED_NORMALIZED" ] && [ "''${SELECTED_NORMALIZED#*: }" != "$SELECTED_NORMALIZED" ]; then
      # Find the matching notification and get its URL.
      URL=$(echo "$NOTIFICATIONS_JSON" | ${getExe pkgs.jq} -r --arg selected "$SELECTED_NORMALIZED" '
        def repo_name:
          .repository.full_name // .repository.name // "Unknown";

        def get_icon:
          if .subject.type == "Issue" then ""
          elif .subject.type == "Discussion" then "󰙯"
          elif .subject.type == "PullRequest" then ""
          elif .subject.type == "Commit" then ""
          else ""
          end;

        .[]
        | select("\(repo_name): \(get_icon) \(.subject.title // "Untitled")" == $selected)
        | .subject.url
      ' | ${getExe' pkgs.coreutils "head"} -n1)
      WEB_URL=$(echo "$URL" | ${getExe pkgs.gnused} -E 's|api\.github\.com/repos/|github.com/|; s|/pulls/|/pull/|')

      ${getExe' pkgs.xdg-utils "xdg-open"} "$WEB_URL"
    fi
  '';
in
{
  "custom/ellipses" = {
    format = "";
    tooltip = false;
  };

  "custom/github" = {
    format = " {text}";
    return-type = "json";
    interval = 60;
    exec = "${getExe githubHelper}";
    on-click = "${getExe' pkgs.coreutils "sleep"} 0.1 && ${getExe githubMenuHelper}";
  };

  "custom/lock" = {
    format = "󰍁";
    tooltip = false;
    on-click = "${getExe config.programs.swaylock.package}";
  };

  "custom/media" = {
    format = "{icon} {}";
    return-type = "json";
    max-length = 40;
    format-icons = {
      spotify = "";
      default = "🎜";
    };
    escape = true;
    exec = "${config.xdg.configHome}/waybar/mediaplayer.py 2> /dev/null";
  };

  "custom/notification" = {
    tooltip = true;
    format = "{icon} {text}";
    format-icons = {
      notification = "<span foreground='red'><sup></sup></span>";
      none = "";
      dnd-notification = "<span foreground='red'><sup></sup></span>";
      dnd-none = "";
      inhibited-notification = "<span foreground='red'><sup></sup></span>";
      inhibited-none = "";
      dnd-inhibited-notification = "<span foreground='red'><sup></sup></span>";
      dnd-inhibited-none = "";
    };
    return-type = "json";
    exec-if = "which ${getExe' config.services.swaync.package "swaync-client"}";
    exec = "${getExe' config.services.swaync.package "swaync-client"} -swb";
    on-click = "${getExe' pkgs.coreutils "sleep"} 0.1 && ${getExe' config.services.swaync.package "swaync-client"} -t -sw";
    on-click-right = "${getExe' pkgs.coreutils "sleep"} 0.1 && ${getExe' config.services.swaync.package "swaync-client"} -d -sw";
    escape = true;
  };

  "custom/power" = {
    format = "";
    tooltip = false;
    menu = "on-click";
    menu-file = pkgs.writeText "powermenu.xml" /* xml */ ''
      <?xml version="1.0" encoding="UTF-8"?>
      <interface>
       <object class="GtkMenu" id="menu">
        <child>
         <object class="GtkMenuItem" id="top">
          <property name="label">Activity</property>
         </object>
        </child>
        <child>
         <object class="GtkSeparatorMenuItem" id="delimiter1"/>
        </child>
        <child>
         <object class="GtkMenuItem" id="lock">
          <property name="label">Lock</property>
         </object>
        </child>
        <child>
         <object class="GtkMenuItem" id="logout">
          <property name="label">Logout</property>
         </object>
        </child>
        <child>
         <object class="GtkMenuItem" id="suspend">
          <property name="label">Suspend</property>
         </object>
        </child>
        <child>
         <object class="GtkMenuItem" id="hibernate">
          <property name="label">Hibernate</property>
         </object>
        </child>
        <child>
         <object class="GtkSeparatorMenuItem" id="delimiter2"/>
        </child>
        <child>
         <object class="GtkMenuItem" id="shutdown">
          <property name="label">Shutdown</property>
         </object>
        </child>
        <child>
         <object class="GtkMenuItem" id="reboot">
          <property name="label">Reboot</property>
         </object>
        </child>
       </object>
      </interface>
    '';
    menu-actions =
      let
        systemctl = getExe' pkgs.systemd "systemctl";
        hyprlock = getExe config.programs.hyprlock.package;
        swaylock = getExe config.programs.swaylock.package;
        poweroff = getExe' pkgs.systemd "poweroff";
        reboot = getExe' pkgs.systemd "reboot";
        terminal = getExe config.programs.kitty.package;
        top = getExe config.programs.btop.package;
      in
      {
        inherit poweroff reboot;

        hibernate = "${systemctl} hibernate";
        lock = /* Bash */ ''([[ "$XDG_CURRENT_DESKTOP" == "sway" ]] && ${swaylock} -defF) || ([[ "$XDG_CURRENT_DESKTOP" == "Hyprland" ]] && ${hyprlock} --immediate)'';
        suspend = "${systemctl} suspend";
        top = "${terminal} ${top}";
        logout =
          if (osConfig.programs.uwsm.enable or false) then "uwsm stop" else "loginctl terminate-user $USER";
      };
  };

  "custom/separator-right" = {
    format = "";
    tooltip = false;
  };

  "custom/separator-left" = {
    format = "";
    tooltip = false;
  };

  "custom/weather" = {
    exec = "${getExe pkgs.wttrbar} --fahrenheit --ampm${
      lib.optionalString (osConfig.khanelinix.security.sops.enable or false
      ) " --location $(jq '.wttr.location' ${config.home.homeDirectory}/weather_config.json)"
    }";
    return-type = "json";
    format = "{}";
    tooltip = true;
    interval = 3600;
  };

  "custom/wlogout" = {
    format = "";
    interval = "once";
    tooltip = false;
    on-click = "${getExe' pkgs.coreutils "sleep"} 0.1 && ${getExe pkgs.wlogout} -c 5 -r 5 -p layer-shell";
  };
}
