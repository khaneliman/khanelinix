{
  config,
  lib,
  pkgs,

  # osConfig ? { },
  ...
}:
let
  cfg = config.khanelinix.programs.graphical.launchers.vicinae;
  raycastRev = "e3b6229c1a4b12e31f17689a1be7b03988270556";

  # isWSL = osConfig.khanelinix.archetypes.wsl.enable or false;

  mkRaycastExtension =
    { name, sha256 }:
    config.lib.vicinae.mkRayCastExtension {
      inherit name sha256;
      rev = raycastRev;
    };
in
{
  options.khanelinix.programs.graphical.launchers.vicinae = {
    enable = lib.mkEnableOption "vicinae in the desktop environment";
  };

  config = lib.mkIf cfg.enable {
    programs.vicinae = {
      enable = true;
      package = pkgs.vicinae;

      # NOTE: Use `nix run .#update-vicinae-extensions` to refresh these pins.
      extensions = map mkRaycastExtension (
        [
          {
            name = "base64";
            sha256 = "sha256-rY876rx/TEFPOeIoA8J5c2fjr1/k/xegCH/4szdwUE0=";
          }
          {
            name = "browser-bookmarks";
            sha256 = "sha256-0EmO/3W6kKpvNzizOWSapf69xull9GOAb2nJq30I4cM=";
          }
          {
            name = "browser-history";
            sha256 = "sha256-Hg63K00z4KRvNrm9KeQpFjFdF08NXkAJ76zoAQ6VFWI=";
          }
          {
            name = "browser-tabs";
            sha256 = "sha256-oNa/6NGdenTKHWm75bsig4JKY3DHBI7cX9gCaHKlOYk=";
          }
          {
            name = "calendar";
            sha256 = "sha256-GkhODmoFS7GZDSi2QhyWGMwT91wfeAv5vDdbSdyyhno=";
          }
          {
            name = "cheatsheets";
            sha256 = "sha256-xno6xb3foSItmOuxU2I67M8TBjHUv/KtnB0WnHrj40U=";
          }
          # FIXME: hangs forever
          # "color-picker"
          {
            name = "conventional-commits";
            sha256 = "sha256-G19OJfYdiwzxZRbV7gcoVDQCi55+ubpu3e7l4NOmoJ8=";
          }
          {
            name = "dad-jokes";
            sha256 = "sha256-VjKEepMWaZrDYpvSpQ1TH0eZAUbgTruM7KQSEMlOhoY=";
          }
          {
            name = "gif-search";
            sha256 = "sha256-es1GDe906h/vNmzd6ZY2kWSZGIvTuwByrGde2m1Zlyc=";
          }
          {
            name = "tldr";
            sha256 = "sha256-JHHvyNPGw0mRqo7SQXiPSN8qVa8Tlri0g0i7h6R2bao=";
          }
          {
            name = "weather";
            sha256 = "sha256-NB7jsFhoO0n6I5oDloTCK6z5ksoEzS0l48yHUnGh7BY=";
          }
          {
            name = "window-walker";
            sha256 = "sha256-L3XTv91z87bakLS4C10L0adcJJbAVLX15T/2c7TVjpY=";
          }
          {
            name = "world-clock";
            sha256 = "sha256-7HGaEwwLxUKz9h+WrWep6hA5dJpqFbAHPKAfFVjF+7I=";
          }
          # FIXME: broken extension candidates (build/runtime issues in CI)
          # npm error path /build/bitwarden/node_modules/electron
          # npm error RequestError: getaddrinfo EAI_AGAIN github.com
          # npm error     at GetAddrInfoReqWrap.onlookupall [as oncomplete] (node:dns:122:26)
          # "bitwarden"
          # FIXME: broken extension candidates (build/runtime issues in CI)
          # /build/claude/node_modules/.bin/ray: line 36: curl: command not found
          # /build/claude/node_modules/.bin/ray: line 71: /build/claude/node_modules/@raycast/api/bin/linux/ray: No such file or directory
          # "claude"
        ]
        # FIXME: broken extension candidates (build/runtime issues in CI)
        # /build/postman/node_modules/.bin/ray: line 30: curl: command not found
        # /build/postman/node_modules/.bin/ray: line 65: /build/postman/node_modules/@raycast/api/bin/linux/ray: No such file or directory
        # ++ lib.optional (config.khanelinix.suites.development.enable && !isWSL) {
        #   name = "postman";
        #   sha256 = "";
        # }
        # FIXME: broken extension candidates (build/runtime issues in CI)
        # cp: missing destination file operand after '/nix/store/big3djc5djq0lgx3xi00ygwbmd22jnxk-visual-studio-code-recent-projects/'
        # ++ lib.optional config.khanelinix.programs.graphical.editors.vscode.enable {
        #   name = "visual-studio-code-recent-projects";
        #   sha256 = "";
        # }
        ++ lib.optional config.khanelinix.programs.terminal.emulators.warp.enable {
          name = "warp";
          sha256 = "sha256-wBu5LzTvTWsT7SDePYY4rBPEToa23PMRvKfiIqABuZ8=";
        }
        ++ lib.optionals config.khanelinix.suites.business.enable [
          {
            name = "1password";
            sha256 = "sha256-wZUe66wjY855zygpOv1lYAyRqXZXJAVgkHnQlygaDzM=";
          }
          {
            name = "slack";
            sha256 = "sha256-i0P0z9PNy4CPX79MV7EEhAjmwtUaYN2GDhYfhCFfExY=";
          }
        ]
        ++ lib.optionals config.khanelinix.suites.development.enable [
          {
            name = "github";
            sha256 = "sha256-bZKhSOz5u6rFRX97J6bxDvNQJGKXh/EtkNxDjUJBKIQ=";
          }
          {
            name = "gitlab";
            sha256 = "sha256-cNg0+40ZIGnx+NOpDsaMdYRSJfu5WdJlA6Z9A6qKSh8=";
          }
        ]
        ++ lib.optional config.khanelinix.suites.development.dockerEnable {
          name = "docker";
          sha256 = "sha256-K7qiT53LJRDjw6dEHKgZvJjtpBOMalJJADM6hQZf518=";
        }
        ++ lib.optionals config.khanelinix.suites.social.enable [
          {
            name = "telegram";
            sha256 = "sha256-UTilgwb/OubiJt0Zbb9t/IsaRN1PwVyhn6DCYM9GAFE=";
          }
          {
            name = "twitch";
            sha256 = "sha256-7uKcD/cQhoS8B1xilkKCna16E9SE0o0zSsmING3CpAE=";
          }
        ]
        ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin (
          [
            {
              name = "brew";
              sha256 = "sha256-mL3Hm1w3AdpOjSLIXusPegXKe5j6njVBm0nWZYrQIWo=";
            }
          ]
          ++ lib.optional config.khanelinix.programs.graphical.wms.aerospace.enable {
            name = "aerospace";
            sha256 = "sha256-QcDTZ269K6AhLSuqiiKdzsoIMFh9k4Lapp3k2g+ekaE=";
          }
        )
      );

      systemd = {
        enable = true;
      };

      settings = {
        "$schema" = "https://vicinae.com/schemas/config.json";
        fallbacks = [ ];
        search_files_in_root = false;
        providers.files.preferences = {
          autoIndexing = false;
          paths = "";
          excludedPaths = config.home.homeDirectory;
          watcherPaths = "";
        };
      };
    };

    systemd.user.services.vicinae = lib.mkIf config.programs.vicinae.systemd.enable {
      Unit = {
        After = lib.mkAfter [ "xdg-desktop-portal.service" ];
        Wants = [ "xdg-desktop-portal.service" ];
      };
    };
  };
}
