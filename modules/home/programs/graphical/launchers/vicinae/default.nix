{
  config,
  lib,

  pkgs,
  ...
}:
let
  cfg = config.khanelinix.programs.graphical.launchers.vicinae;
in
{
  options.khanelinix.programs.graphical.launchers.vicinae = {
    enable = lib.mkEnableOption "vicinae in the desktop environment";
  };

  config = lib.mkIf cfg.enable {
    programs.vicinae = {
      enable = true;
      package = pkgs.vicinae;

      # NOTE: Kinda annoying to have to manually fetch these revs.
      # Might be nice to automate this
      extensions = [
        (config.lib.vicinae.mkRayCastExtension {
          name = "1password";
          rev = "1d1357202ec181978a698871b311f93d656122f6";
          sha256 = "sha256-JZdM4l3m3JQWoGqJOPoaywpSnlWA7pcEJjII24YMSEA=";
        })
        (config.lib.vicinae.mkRayCastExtension {
          name = "base64";
          rev = "9befbb8bad621365a0f2896a13f6fb26fecb8d55";
          sha256 = "sha256-T/utRy3ptNlC+v3X9ebnzRuCLVlSkZnm7sRwikIVeAk=";
        })
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
        # (config.lib.vicinae.mkRayCastExtension {
        #   name = "conventional-commits";
        #   rev = "13e481b7e1a8393f5b7d3044c489d57ada298ce6";
        #   sha256 = "sha256-oyVMU2RfXuaaEk27/vOyCwYq4NNirksawrvG0ZBe47w=";
        # })
        (config.lib.vicinae.mkRayCastExtension {
          name = "dad-jokes";
          rev = "b8c8fcd7ebd441a5452b396923f2a40e879565ba";
          sha256 = "sha256-07IYIMKQjGlVWSDN1CX8wGOrx3Ob1beZeGmhaEMQYa4=";
        })
        (config.lib.vicinae.mkRayCastExtension {
          name = "gif-search";
          rev = "4d417c2dfd86a5b2bea202d4a7b48d8eb3dbaeb1";
          sha256 = "sha256-G7il8T1L+P/2mXWJsb68n4BCbVKcrrtK8GnBNxzt73Q=";
        })
        (config.lib.vicinae.mkRayCastExtension {
          name = "github";
          rev = "238052eeb0e2fb9acb1f9418dd7178eafac5e5cf";
          sha256 = "sha256-WjikX+a0h7Z65jhwclpjHLweEuPulG4wptGJiJfMT+0=";
        })
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
        (config.lib.vicinae.mkRayCastExtension {
          name = "amphetamine";
          rev = "d480d47a5c3271f36134614ecdc49b2d447bccf2";
          sha256 = "sha256-DiAtPqcFWGNwBl2ZYXaDYBqIbD0yAevsHjL3YTbXGwI=";
        })
        (config.lib.vicinae.mkRayCastExtension {
          name = "brew";
          rev = "b8c8fcd7ebd441a5452b396923f2a40e879565ba";
          sha256 = "sha256-c0FdaXt24JF6cmjVd8aXQ6TrO5QiEJ4vt2DntAj9MlM=";
        })
      ];

      systemd = {
        enable = true;
      };

      settings = {
        "$schema" = "https://vicinae.com/schemas/config.json";
      };
    };
  };
}
