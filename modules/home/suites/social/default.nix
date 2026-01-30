{
  config,
  lib,

  pkgs,
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

  config = mkIf cfg.enable {
    home.packages =
      with pkgs;
      [
        (element-desktop.overrideAttrs (
          lib.optionalAttrs pkgs.stdenv.isDarwin {
            env.CSC_IDENTITY_AUTO_DISCOVERY = "false";
            postPatch = ''
              cp -r ${electron.dist} electron-dist
              chmod -R u+w electron-dist

              substituteInPlace package.json \
                --replace-fail \
                ' electron-builder",' \
                ' electron-builder --dir -c.electronDist=electron-dist -c.electronVersion=${electron.version} -c.mac.identity=null",'

              # `@electron/fuses` tries to run `codesign` and fails. Disable and use autoSignDarwinBinariesHook instead
              substituteInPlace ./electron-builder.ts \
                --replace-fail "resetAdHocDarwinSignature:" "// resetAdHocDarwinSignature:" \
                --replace-fail 'target: ["dmg", "zip"],' 'target: "dir",' \
                --replace-fail 'icon: "build/icon.icon",' '// icon: "build/icon.icon",'

              # Need to disable asar integrity check to copy in native seshat files, see postBuild phase
              substituteInPlace ./electron-builder.ts \
                --replace-fail "enableEmbeddedAsarIntegrityValidation: true" "enableEmbeddedAsarIntegrityValidation: false"
            '';
          }
        ))
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
        # TODO: migrate to darwin after version bump
        slack
        telegram-desktop
      ];

    khanelinix = {
      programs = {
        graphical.apps = {
          caprine = lib.mkDefault enabled;
          # FIXME: broken darwin
          vesktop = mkIf pkgs.stdenv.hostPlatform.isLinux (lib.mkDefault enabled);
        };

        terminal.social = {
          slack-term = lib.mkDefault enabled;
          twitch-tui = lib.mkDefault enabled;
        };
      };
    };
  };
}
