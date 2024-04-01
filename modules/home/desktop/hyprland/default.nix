{ config
, lib
, pkgs
, inputs
, ...
}:
let
  inherit (lib) mkIf mkEnableOption mkForce getExe;
  inherit (lib.internal) enabled;
  inherit (inputs) hyprland;

  cfg = config.khanelinix.desktop.hyprland;

  historicalLogAliases = builtins.listToAttrs (builtins.genList
    (
      x:
      {
        name = "hl${toString (x + 1)}";
        value = "cat /tmp/hypr/$(command ls -t /tmp/hypr/ | grep -v '\.lock$' | head -n ${toString (x + 2)} | tail -n 1)/hyprland.log";
      }
    )
    4);

  historicalCrashAliases = builtins.listToAttrs (builtins.genList
    (
      x:
      {
        name = "hlc${toString (x + 1)}";
        value = "cat /home/${config.khanelinix.user.name}/.local/cache/hyprland/$(command ls -t /home/${config.khanelinix.user.name}/.local/cache/hyprland/ | grep 'hyprlandCrashReport' | head -n ${toString (x + 2)} | tail -n 1)";
      }
    )
    4);
in
{
  options.khanelinix.desktop.hyprland = {
    enable = mkEnableOption "Hyprland.";
    appendConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Extra configuration lines to add to bottom of `~/.config/hypr/hyprland.conf`.
      '';
    };
    prependConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Extra configuration lines to add to top of `~/.config/hypr/hyprland.conf`.
      '';
    };
  };

  imports = lib.snowfall.fs.get-non-default-nix-files ./.;

  config =
    mkIf cfg.enable
      {
        home.shellAliases = {
          hl = "cat /tmp/hypr/$(command ls -t /tmp/hypr/ | grep -v '\.lock$' | head -n 1)/hyprland.log";
          hlc = "cat /home/${config.khanelinix.user.name}/.local/cache/hyprland/$(command ls -t /home/${config.khanelinix.user.name}/.local/cache/hyprland/ | grep 'hyprlandCrashReport' | head -n 1)";
        } // historicalLogAliases // historicalCrashAliases;

        khanelinix = {
          desktop.addons = {
            rofi = enabled;
            hyprpaper = {
              enable = true;
              enableSocketWatch = true;
            };
            hypridle = enabled;
            hyprlock = enabled;
          };

          suites = {
            wlroots = enabled;
          };
        };

        programs.waybar.systemd.target = "hyprland-session.target";

        systemd.user.services.hypridle.Install.WantedBy = lib.mkForce [ "hyprland-session.target" ];

        wayland.windowManager.hyprland = {
          enable = true;

          extraConfig = /* bash */ ''
            ${cfg.prependConfig}

            env = XDG_DATA_DIRS,'${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}':$XDG_DATA_DIRS
            env = HYPRLAND_TRACE,1

            ${cfg.appendConfig}
          '';

          # package = hyprland.packages.${system}.hyprland;
          package = pkgs.hyprland;

          settings = {
            exec = [
              "${getExe pkgs.libnotify} --icon ~/.face -u normal \"Hello $(whoami)\""
            ];
          };

          systemd = {
            enable = true;
          };

          xwayland.enable = true;
        };
      };
}
