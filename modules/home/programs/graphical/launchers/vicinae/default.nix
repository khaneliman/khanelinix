{
  config,
  lib,
  pkgs,

  # osConfig ? { },
  ...
}:
let
  inherit (lib.khanelinix) suiteProfileIncludes;

  cfg = config.khanelinix.programs.graphical.launchers.vicinae;
  raycastRev = "e3b6229c1a4b12e31f17689a1be7b03988270556";
  businessIncludes = suiteProfileIncludes config config.khanelinix.suites.business;
  socialIncludes = suiteProfileIncludes config config.khanelinix.suites.social;

  # isWSL = osConfig.khanelinix.archetypes.wsl.enable or false;

  mkRaycastExtension =
    {
      name,
      sha256,
      npmDepsHash,
    }:
    config.lib.vicinae.mkRayCastExtension {
      inherit name sha256 npmDepsHash;
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
            npmDepsHash = "sha256-PoYZFH5HJEmbRBPrZD2ArCchytgzwoq3MCuyHVri60E=";
          }
          {
            name = "browser-bookmarks";
            sha256 = "sha256-0EmO/3W6kKpvNzizOWSapf69xull9GOAb2nJq30I4cM=";
            npmDepsHash = "sha256-I//QQtQWKnNos1etKmAbJs2Jg9tbfpI0SMt3k6S1fkw=";
          }
          {
            name = "browser-history";
            sha256 = "sha256-Hg63K00z4KRvNrm9KeQpFjFdF08NXkAJ76zoAQ6VFWI=";
            npmDepsHash = "sha256-UgSl45qpkeDf92XWrbJBCcLgeGJLyDUrJzsQFtHHgKY=";
          }
          {
            name = "browser-tabs";
            sha256 = "sha256-oNa/6NGdenTKHWm75bsig4JKY3DHBI7cX9gCaHKlOYk=";
            npmDepsHash = "sha256-tiAhDUAZ2CcVJGTiUM4TAoOtM20djSz0bzR8J8T6e6w=";
          }
          {
            name = "calendar";
            sha256 = "sha256-GkhODmoFS7GZDSi2QhyWGMwT91wfeAv5vDdbSdyyhno=";
            npmDepsHash = "sha256-Ib5wOEoJT2j4iuuR2hCTzkXBbu41hFNhKlUAh57PbNE=";
          }
          {
            name = "cheatsheets";
            sha256 = "sha256-xno6xb3foSItmOuxU2I67M8TBjHUv/KtnB0WnHrj40U=";
            npmDepsHash = "sha256-+OMA+g1Eve0Hg+a3uVqZdgmT2aw0yeo8GyDDmFnNXDQ=";
          }
          # FIXME: hangs forever
          # "color-picker"
          {
            name = "conventional-commits";
            sha256 = "sha256-G19OJfYdiwzxZRbV7gcoVDQCi55+ubpu3e7l4NOmoJ8=";
            npmDepsHash = "sha256-YFVVjAWQnWXWan0vj95t6u09rP8lgKUu1Pr97r6XrkY=";
          }
          {
            name = "dad-jokes";
            sha256 = "sha256-VjKEepMWaZrDYpvSpQ1TH0eZAUbgTruM7KQSEMlOhoY=";
            npmDepsHash = "sha256-wLxS0udCSpzHmj1HA7bgGAxBebAN/0brn1ppzQDg2MM=";
          }
          {
            name = "gif-search";
            sha256 = "sha256-es1GDe906h/vNmzd6ZY2kWSZGIvTuwByrGde2m1Zlyc=";
            npmDepsHash = "sha256-kqiR9jgv/mwtI9LUPNAJ4OVECTQo91ZxS8spBethGVw=";
          }
          {
            name = "tldr";
            sha256 = "sha256-JHHvyNPGw0mRqo7SQXiPSN8qVa8Tlri0g0i7h6R2bao=";
            npmDepsHash = "sha256-/I8wqJ1zLGCk715YkLnE52qs13maov5H6Yc3uAtqR/A=";
          }
          {
            name = "weather";
            sha256 = "sha256-NB7jsFhoO0n6I5oDloTCK6z5ksoEzS0l48yHUnGh7BY=";
            npmDepsHash = "sha256-lce/RN4wycOeLL++sZVYZWq0AZTzYLm8Wrqp/VKvRl8=";
          }
          {
            name = "window-walker";
            sha256 = "sha256-L3XTv91z87bakLS4C10L0adcJJbAVLX15T/2c7TVjpY=";
            npmDepsHash = "sha256-Ri354YJ61Y23u36VfG1n2rPFqh7dkTtSOKwnE2ThhSg=";
          }
          {
            name = "world-clock";
            sha256 = "sha256-7HGaEwwLxUKz9h+WrWep6hA5dJpqFbAHPKAfFVjF+7I=";
            npmDepsHash = "sha256-itWBlCAXAISrSCFIJhzvppU3Ovvkxi+fRiP+G3I+azQ=";
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
          npmDepsHash = "sha256-Pirsjf99/2ZPwdRFKF2cZ0QFlQi/YE2DasbTsEJiahM=";
        }
        ++ lib.optional config.khanelinix.suites.business.enable {
          name = "1password";
          sha256 = "sha256-wZUe66wjY855zygpOv1lYAyRqXZXJAVgkHnQlygaDzM=";
          npmDepsHash = "sha256-VIoAMS0/Sl3A8MMsMgqRlZs6dpk2fhMJrREjwj9CDjA=";
        }
        ++ lib.optional (config.khanelinix.suites.business.enable && businessIncludes "maximal") {
          name = "slack";
          sha256 = "sha256-i0P0z9PNy4CPX79MV7EEhAjmwtUaYN2GDhYfhCFfExY=";
          npmDepsHash = "sha256-DeUjKPjd/haeBmSw7jrudpNcvc7twCcDpOe50s40ZvI=";
        }
        ++ lib.optionals config.khanelinix.suites.development.enable [
          {
            name = "github";
            sha256 = "sha256-bZKhSOz5u6rFRX97J6bxDvNQJGKXh/EtkNxDjUJBKIQ=";
            npmDepsHash = "sha256-Tqz6yif7bgdw2yVaWjibNBpgzmMpn7J4wcVLRhuKDXI=";
          }
          {
            name = "gitlab";
            sha256 = "sha256-cNg0+40ZIGnx+NOpDsaMdYRSJfu5WdJlA6Z9A6qKSh8=";
            npmDepsHash = "sha256-CL9wWQZm2VTCriB7gQZBksdPj/eYKicCLbNT4E2jo5c=";
          }
        ]
        ++ lib.optional config.khanelinix.suites.development.dockerEnable {
          name = "docker";
          sha256 = "sha256-K7qiT53LJRDjw6dEHKgZvJjtpBOMalJJADM6hQZf518=";
          npmDepsHash = "sha256-Hnj4w7daE3KJDSrjPNGehQkYV2EjGkhYVlifmHy4pAg=";
        }
        ++ lib.optionals (config.khanelinix.suites.social.enable && socialIncludes "maximal") [
          {
            name = "telegram";
            sha256 = "sha256-UTilgwb/OubiJt0Zbb9t/IsaRN1PwVyhn6DCYM9GAFE=";
            npmDepsHash = "sha256-wmHeFPsRrRCI4jk52gJHXVJn4FlfVCKL4nRoLi2zoUg=";
          }
          {
            name = "twitch";
            sha256 = "sha256-7uKcD/cQhoS8B1xilkKCna16E9SE0o0zSsmING3CpAE=";
            npmDepsHash = "sha256-GHJ/n2MJSY/yDsG/HIavVqSAtkNYOLNTssNrdV8iKUs=";
          }
        ]
        ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin (
          [
            {
              name = "brew";
              sha256 = "sha256-mL3Hm1w3AdpOjSLIXusPegXKe5j6njVBm0nWZYrQIWo=";
              npmDepsHash = "sha256-uuF2NxFFTzOOsgQ0dSETL3JU8l9tE4q5NXa/to8YLTc=";
            }
          ]
          ++ lib.optional config.khanelinix.programs.graphical.wms.aerospace.enable {
            name = "aerospace";
            sha256 = "sha256-QcDTZ269K6AhLSuqiiKdzsoIMFh9k4Lapp3k2g+ekaE=";
            npmDepsHash = "sha256-bLDtsxZP2f51Uho/Dh4mj+6Ygyhxmvh3FIGCh4z5AlE=";
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

      Service = {
        KillMode = lib.mkForce "control-group";
        TimeoutStopSec = "10s";
      };
    };
  };
}
