{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    types
    mkIf
    getExe
    getExe'
    ;
  inherit (lib.khanelinix) mkOpt;

  cfg = config.khanelinix.display-managers.regreet;
  themeCfg = config.khanelinix.theme;
  gtkCfg = config.khanelinix.desktop.addons.gtk;

  # regreet remembers the last user in /var/lib/regreet/state.toml; seed it so
  # the very first login is already populated. The empty user_to_last_sess
  # table is required — the Cache struct has no serde defaults, and a partial
  # file would fail to parse (regreet would then just fall back to defaults).
  seedStateFile = pkgs.writeText "regreet-state.toml" ''
    last_user = "${config.khanelinix.user.name}"

    [user_to_last_sess]
  '';

  greetdHyprlandConfig = pkgs.writeText "greetd-hyprland.lua" ''
    ${cfg.hyprlandOutput}

    hl.config({
      animations = {
        enabled = false,
      },
      misc = {
        disable_hyprland_logo = true,
        force_default_wallpaper = 0,
      },
    })

    hl.bind("SUPER + RETURN", hl.dsp.exec_cmd(${builtins.toJSON (getExe pkgs.wezterm)}))
    hl.bind("SUPER + SHIFT + RETURN", hl.dsp.exec_cmd(${builtins.toJSON (getExe pkgs.nwg-hello)}))
    hl.bind("SUPER + CTRL + SHIFT + RETURN", hl.dsp.exec_cmd(${builtins.toJSON (getExe pkgs.greetd.regreet)}))

    hl.on("hyprland.start", function()
      hl.exec_cmd(${builtins.toJSON "${lib.getExe' pkgs.dbus "dbus-update-activation-environment"} --systemd DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE"})
      hl.exec_cmd(${builtins.toJSON "${getExe pkgs.greetd.regreet} -l debug && ${getExe' pkgs.hyprland-unwrapped "hyprctl"} exit"})
    end)

  '';
in
{
  options.khanelinix.display-managers.regreet = with types; {
    enable = lib.mkEnableOption "greetd";
    hyprlandOutput = mkOpt lines "" "Hyprland Lua output config.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      themeCfg.cursor.package
      themeCfg.icon.package
      gtkCfg.theme.package
    ];

    programs.regreet = {
      # ReGreet documentation
      # See: https://github.com/rharish101/ReGreet
      enable = true;

      settings = {
        background = {
          path = lib.khanelinix.theme.wallpaperPath {
            inherit config pkgs;
            name = config.khanelinix.theme.wallpaper.primary;
          };
          fit = "Cover";
        };

        GTK = {
          application_prefer_dark_theme = true;
          cursor_theme_name = "${themeCfg.cursor.name}";
          font_name = "${config.khanelinix.system.fonts.default} * 12";
          icon_theme_name = "${themeCfg.icon.name}";
          theme_name = "${gtkCfg.theme.name}";
        };
      };
    };

    services.greetd = {
      settings = {
        default_session = {
          command = "${getExe pkgs.hyprland-unwrapped} --config ${greetdHyprlandConfig} > /tmp/hyprland-log-out.txt 2>&1";
        };
      };

      restart = false;
    };

    security.pam.services.greetd = {
      enableGnomeKeyring = true;
      gnupg.enable = true;
    };

    # C = copy only when the destination is missing, so regreet's own
    # last-user tracking still wins after the first login (C+ would force it
    # every boot)
    systemd.tmpfiles.rules = [
      "C /var/lib/regreet/state.toml 0644 greeter greeter - ${seedStateFile}"
    ];
  };
}
