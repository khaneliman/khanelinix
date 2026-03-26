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
          rev = "a85ee78f874a6366549cdb59b87bb6a3e00327da";
          sha256 = "sha256-O3rnnjwzAsA9odQnK8V9VcWoaVl1miOkRqXv6mS8m4E=";
        })
        (config.lib.vicinae.mkRayCastExtension {
          name = "base64";
          rev = "04ca0dccbfffc425de8ec56934964802fa48d387";
          sha256 = "sha256-WPeUJt41OE2EwwjVV46jScR25R2wJUoylZyd1IEc/a4=";
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
          rev = "6d32581cfaeabd8d7b3d570183b52bae31745ce2";
          sha256 = "sha256-/59ZaKe6gUkemauakgSvwkb76kN3aciKHgAh2yYk6jI=";
        })
        (config.lib.vicinae.mkRayCastExtension {
          name = "github";
          rev = "9c0dffd40db3ee0ca852645b4513b536df73bc8b";
          sha256 = "sha256-bZKhSOz5u6rFRX97J6bxDvNQJGKXh/EtkNxDjUJBKIQ=";
        })
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
        (config.lib.vicinae.mkRayCastExtension {
          name = "amphetamine";
          rev = "ad9f7d6a489332bc17d8428f602e507884b2f652";
          sha256 = "sha256-dqJhfcZCb2UP2NN6s9emkEFe773kxUczaYCkBzwvekE=";
        })
        (config.lib.vicinae.mkRayCastExtension {
          name = "brew";
          rev = "9811ea6931ade6fb9116d9001a26d29edeb2f5fb";
          sha256 = "sha256-mL3Hm1w3AdpOjSLIXusPegXKe5j6njVBm0nWZYrQIWo=";
        })
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
