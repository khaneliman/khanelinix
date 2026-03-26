{
  config,
  inputs,
  lib,

  pkgs,
  ...
}:
let
  cfg = config.khanelinix.programs.graphical.launchers.vicinae;
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
      extensions = [
        (mkRaycastExtension "1password")
        (mkRaycastExtension "base64")
        # FIXME: broken build
        # (config.lib.vicinae.mkRayCastExtension {
        #   name = "bitwarden";
        #   rev = "b8c8fcd7ebd441a5452b396923f2a40e879565ba";
        #   sha256 = "sha256-N1zAPZJmmfvSw425MQDopSm/stu1IRI2t17xo8Ml+8g=";
        # })
        # (config.lib.vicinae.mkRayCastExtension {
        #   name = "claude";
        #   rev = "d9ec03d0ce2290682b8d03749c09807ff2c1e064";
        #   sha256 = "sha256-vSm64genQfBpLb541aqNkObi9Ri0T71nrw8wDFfM/Rc=";
        # })
        # (mkRaycastExtension "conventional-commits")
        (mkRaycastExtension "dad-jokes")
        (mkRaycastExtension "gif-search")
        (mkRaycastExtension "github")
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
        (mkRaycastExtension "amphetamine")
        (mkRaycastExtension "brew")
      ];

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
