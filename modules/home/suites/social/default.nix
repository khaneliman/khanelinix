{
  config,
  lib,

  pkgs,
  getPkgsUnstable,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.khanelinix) enabled;

  cfg = config.khanelinix.suites.social;
in
{
  options.khanelinix.suites.social = {
    enable = lib.mkEnableOption "social configuration";
  };

  config = mkIf cfg.enable (
    let
      pkgsUnstable = getPkgsUnstable pkgs.stdenv.hostPlatform.system { inherit (pkgs) config; };
    in
    {
      home.packages = [
        (pkgs.element-desktop.overrideAttrs (old: {
          # NOTE: Fix electron app_id
          postPatch = (old.postPatch or "") + ''
              substituteInPlace apps/desktop/package.json \
                --replace-fail '"productName": "Element",' '"desktopName": "Element.desktop",
            "productName": "Element",'
          '';
        }))
      ]
      ++ [
        pkgsUnstable.telegram-desktop
      ];

      khanelinix = {
        programs = {
          graphical.apps = {
            caprine = lib.mkDefault enabled;
            vesktop = lib.mkDefault enabled;
          };

          terminal.social = {
            twitch-tui = lib.mkDefault enabled;
          };
        };
      };
    }
  );
}
