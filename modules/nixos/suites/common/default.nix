{ config
, lib
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) enabled;

  cfg = config.khanelinix.suites.common;
in
{
  imports = [ ../../../shared/suites/common/default.nix ];

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      appimage-run
      clac
      feh
      fzf
      jq
      khanelinix.trace-symlink
      khanelinix.trace-which
      ncdu
      toilet
      upower
      util-linux
    ];

    khanelinix = {
      nix = enabled;

      cli-apps = {
        fastfetch = enabled;
        ranger = enabled;
      };

      tools = {
        colorls = enabled;
        comma = enabled;
        fup-repl = enabled;
        git = enabled;
        glxinfo = enabled;
        nix-ld = enabled;
        spicetify-cli = enabled;
      };

      hardware = {
        audio = enabled;
        power = enabled;
        storage = enabled;
      };

      services = {
        openssh = enabled;
        printing = enabled;
        tailscale = enabled;
      };

      security = {
        doas = enabled;
        gpg = enabled;
        keyring = enabled;
        polkit = enabled;
      };

      system = {
        boot = enabled;
        fonts = enabled;
        locale = enabled;
        networking = enabled;
        time = enabled;
        xkb = enabled;
      };
    };
  };
}
