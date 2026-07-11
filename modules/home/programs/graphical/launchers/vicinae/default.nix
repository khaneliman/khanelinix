{
  config,
  lib,
  pkgs,

  osConfig ? { },
  ...
}:
let
  inherit (lib.khanelinix) suiteProfileIncludes;

  cfg = config.khanelinix.programs.graphical.launchers.vicinae;
  raycastRev = "2a7b7ffb381ee92eca7a28b422965246c78c09a0";
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
            sha256 = "sha256-WR93MSReHXxWkqhpgvE8iaHcPr+dDs2sghK9g6gJot0=";
            npmDepsHash = "sha256-g/RT+ZAAmtJtUCeexoOp07/wW7HiLKzMOXwRp9pqiLQ=";
          }
          {
            name = "browser-bookmarks";
            sha256 = "sha256-ATowV1EqMQ4kqEARGSkopX9r4xUBfM9RB3cfW2IXXO0=";
            npmDepsHash = "sha256-6RXhV8nQ2cmmrmoWz4VjcqdebnoBxegXJc7hZCbJ1F4=";
          }
          {
            name = "browser-history";
            sha256 = "sha256-lpAuVXIgcIqd4aa2kK3S4eDhYA/Sxx9+mrjqr1xg1N8=";
            npmDepsHash = "sha256-g1P+5RcyYRd+LbtxakSwVGD4s29N9Z0a6fj6GJ5CbPk=";
          }
          {
            name = "browser-tabs";
            sha256 = "sha256-TArCdPprg4eXtx+8puY/Ipy4ivBsgHaPXFMEw4AY7MA=";
            npmDepsHash = "sha256-anxLOeTqZB9Vd5/doJebLCzuKd2H9iQt886qQwTUlC8=";
          }
          {
            name = "calendar";
            sha256 = "sha256-xr2v2GwXEE1QJpe4OljcHYveBSiw69splSsCyT9gJIY=";
            npmDepsHash = "sha256-/yohICk4V0yEBH8wTdmmjSCJBsJPB0GjDfvxhptmpiI=";
          }
          {
            name = "cheatsheets";
            sha256 = "sha256-3ZRSFjRMHD6GP+mGkfJgdGPZ4Vp7j4d6ja5crXutaTI=";
            npmDepsHash = "sha256-ZhPJQvhm4i5utXfW6r2q/b7+Rs6UPyTFnGohHuMpkP0=";
          }
          # FIXME: hangs forever
          # "color-picker"
          {
            name = "conventional-commits";
            sha256 = "sha256-Kfm/d+OeTjA4nQdKcbgyk3+eNGDrDowxO6eAGxTzjgU=";
            npmDepsHash = "sha256-YFVVjAWQnWXWan0vj95t6u09rP8lgKUu1Pr97r6XrkY=";
          }
          {
            name = "dad-jokes";
            sha256 = "sha256-hh06bx3eGqbSQ0BacOhZ5yPFTY5AjQ6ui16dAtyG7KA=";
            npmDepsHash = "sha256-vwEfu5O4aDgT9hmYI3jpeM/oUwtr8pwz517Dv9szasI=";
          }
          {
            name = "gif-search";
            sha256 = "sha256-neenXhjjQ5Xayt/SPqq+Y3kPytWgOMZmKPfSn6BJN84=";
            npmDepsHash = "sha256-kqEPCxqdmoM1OUmyZ6lPHE8trXiDQkRUpLWD8FcMRX4=";
          }
          {
            name = "tldr";
            sha256 = "sha256-TieqiIZAdOVcScLK583zOwoCBuWx7Ms4mA5zTdfw65I=";
            npmDepsHash = "sha256-OkBtsNOO2M/n4aCurRi230JmjreKsQgfVsKHHyzz7rU=";
          }
          {
            name = "weather";
            sha256 = "sha256-wfPOhyTbjJzQSkRgKjFcARACJEjJp+cDqhytUw3P5e8=";
            npmDepsHash = "sha256-aT4yOJ+pmGjKhOYmDdjmOHfgvp6tr+tuRmi9OcspmrU=";
          }
          {
            name = "window-walker";
            sha256 = "sha256-fh8QwQ1fyfPi9gy/GV0b7Sp6Gs5GvaBVPpzSXOhDTA4=";
            npmDepsHash = "sha256-wtvECI9R7wN+mOnBpuRRa7CG5zPdckmOmKN2waJtE0I=";
          }
          {
            name = "world-clock";
            sha256 = "sha256-LJVeEYnu4n9igUPokiBFLYfNUchvZM7WxnFd2XdQXt4=";
            npmDepsHash = "sha256-CAoevgaWukNJIgx4uSYUNFtSTFiQggQk7g6TVa/TaQs=";
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
          sha256 = "sha256-gsENleXt2ii0FTZBZO+7jBoRXvjnQfazEEcZ5FX/dNc=";
          npmDepsHash = "sha256-OUab384shAv6ijWQiC0xsf3eV+3ahVTaO3sJ9uS0nvs=";
        }
        ++ lib.optional config.khanelinix.suites.business.enable {
          name = "1password";
          sha256 = "sha256-NpAJi443OsEQwGKb/Tpkobn6pmjzwwYvTJjgvfMv/D8=";
          npmDepsHash = "sha256-WsFo+xxZXYzMkN3+1GBTfQMxHhiE8vVXqiCD+eC6AP0=";
        }
        ++ lib.optional (config.khanelinix.suites.business.enable && businessIncludes "maximal") {
          name = "slack";
          sha256 = "sha256-+AKQm1V4AiNPAj3z2zGT00XHU/3PDOaROSEyE8YZJ1s=";
          npmDepsHash = "sha256-/GPBrSgLqB2M1W2F7EwBBmt+CcbRSVLioht0SScPhvw=";
        }
        ++ lib.optionals config.khanelinix.suites.development.enable [
          {
            name = "github";
            sha256 = "sha256-mbzg0AHQMvJtLQQ3Tf9gqum1q0heCkG7fZi8xPur5Mw=";
            npmDepsHash = "sha256-UUzJPT9MNGdUMBAQIy5caNekdfQkJe41eulOjGrS6JU=";
          }
          {
            name = "gitlab";
            sha256 = "sha256-gAU7eQIOHsuPcgAoXNxSQv12h7uIl2wbGz7Hm8RQtPE=";
            npmDepsHash = "sha256-hDF6f8GmZSiln+BxI0WA9uvaZtx2pxUdYCqHWUurtxc=";
          }
        ]
        ++ lib.optional config.khanelinix.suites.development.dockerEnable {
          name = "docker";
          sha256 = "sha256-nrNXZ7DRLKoMgRaJAhshOBoZqDMcqKR5HJ03T3UxZEY=";
          npmDepsHash = "sha256-rBJGbVaeA0SRMrz17K/dqSG1NaAnfD0sgETjf1vOw64=";
        }
        ++ lib.optionals (config.khanelinix.suites.social.enable && socialIncludes "maximal") [
          {
            name = "telegram";
            sha256 = "sha256-ifXYmDNsXY181jpOjkWGS4PmgEmHVNnAOZIMeiAVbKI=";
            npmDepsHash = "sha256-nSszWpFktf+WoaYn9lUfKGqKOFospo9uWUX97Hm/EnU=";
          }
          {
            name = "twitch";
            sha256 = "sha256-iPPNuUGjzOr8goCQzXvzkfw09/LzB7gkCNycMX++DiA=";
            npmDepsHash = "sha256-aFDkvrqPB6/zhX6wjao0UJWNIUv/1BJXPdI9rTBfEJ0=";
          }
        ]
        ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin (
          [
            {
              name = "brew";
              sha256 = "sha256-P+Jeh6yYThK93660BB+BlBPA37xENopaw8dOFfxsEYU=";
              npmDepsHash = "sha256-tb9VwHhWDRHc2Z03JBiuHJApu8KQ6qhgErN9FLlV8eA=";
            }
          ]
          ++ lib.optional config.khanelinix.programs.graphical.wms.aerospace.enable {
            name = "aerospace";
            sha256 = "sha256-I7JkXbVx8i3QBCkm/gFwIYgUAmmlsxQ1V4Ws61W1eOk=";
            npmDepsHash = "sha256-uYL3lVIogQ94/79BdaL5uKUQWaIY8Lt5JectIGTQ2eA=";
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
        providers.applications.preferences.launchPrefix =
          lib.optionalString pkgs.stdenv.hostPlatform.isLinux
            (
              if (osConfig.programs.uwsm.enable or false) then
                "uwsm app -p TimeoutStopSec=15s --"
              else
                "run-as-service"
            );
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
