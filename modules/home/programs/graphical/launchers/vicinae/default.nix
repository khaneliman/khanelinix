{
  config,
  inputs,
  lib,
  pkgs,

  # osConfig ? { },
  ...
}:
let
  cfg = config.khanelinix.programs.graphical.launchers.vicinae;

  # isWSL = osConfig.khanelinix.archetypes.wsl.enable or false;

  mkRaycastExtension =
    name:
    let
      src = inputs.raycast-extensions + "/extensions/${name}";
    in
    pkgs.buildNpmPackage {
      inherit name src;
      installPhase = ''
        runHook preInstall

        mkdir -p $out
        cp -r /build/.config/raycast/extensions/${name}/* $out/

        runHook postInstall
      '';
      npmDeps = pkgs.importNpmLock { npmRoot = src; };
      inherit (pkgs.importNpmLock) npmConfigHook;
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

      # NOTE: These track the repo pinned in flake.lock via raycast-extensions.
      extensions = map mkRaycastExtension (
        [
          "base64"
          "browser-bookmarks"
          "browser-history"
          "browser-tabs"
          "calendar"
          "cheatsheets"
          # FIXME: hangs forever
          # "color-picker"
          "conventional-commits"
          "dad-jokes"
          "gif-search"
          "tldr"
          "weather"
          "window-walker"
          "world-clock"
          # FIXME:
          # npm error path /build/bitwarden/node_modules/electron
          # npm error RequestError: getaddrinfo EAI_AGAIN github.com
          # npm error     at GetAddrInfoReqWrap.onlookupall [as oncomplete] (node:dns:122:26)
          # "bitwarden"
          # FIXME:
          # /build/claude/node_modules/.bin/ray: line 36: curl: command not found
          # /build/claude/node_modules/.bin/ray: line 71: /build/claude/node_modules/@raycast/api/bin/linux/ray: No such file or directory
          # "claude"
        ]
        # FIXME:
        # /build/postman/node_modules/.bin/ray: line 30: curl: command not found
        # /build/postman/node_modules/.bin/ray: line 65: /build/postman/node_modules/@raycast/api/bin/linux/ray: No such file or directory
        # ++ lib.optional (config.khanelinix.suites.development.enable && !isWSL) "postman"
        # FIXME:
        # cp: missing destination file operand after '/nix/store/big3djc5djq0lgx3xi00ygwbmd22jnxk-visual-studio-code-recent-projects/'
        # ++ lib.optional config.khanelinix.programs.graphical.editors.vscode.enable "visual-studio-code-recent-projects"
        ++ lib.optional config.khanelinix.programs.terminal.emulators.warp.enable "warp"
        ++ lib.optionals config.khanelinix.suites.business.enable [
          "1password"
          "slack"
        ]
        ++ lib.optionals config.khanelinix.suites.development.enable [
          "github"
          "gitlab"
        ]
        ++ lib.optional config.khanelinix.suites.development.dockerEnable "docker"
        ++ lib.optionals config.khanelinix.suites.social.enable [
          "telegram"
          "twitch"
        ]
        ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin (
          [
            "amphetamine"
            "brew"
          ]
          ++ lib.optional config.khanelinix.programs.graphical.wms.aerospace.enable "aerospace"
        )
      );

      systemd = {
        enable = true;
      };

      settings = {
        "$schema" = "https://vicinae.com/schemas/config.json";
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
