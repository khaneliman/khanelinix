{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.suites.common;
in
{
  imports = [ ../../../shared/suites/common/default.nix ];

  options.khanelinix.suites.common = with types; {
    enable = mkBoolOpt false "Whether or not to enable common configuration.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      appimage-run
      bottom
      clac
      feh
      fzf
      jq
      pciutils
      toilet
      upower
      util-linux

      # libaries
      at-spi2-atk
    ];

    khanelinix = {
      nix = enabled;

      cli-apps = {
        btop = enabled;
        fastfetch = enabled;
        ranger = enabled;
      };

      tools = {
        bat = enabled;
        comma = enabled;
        colorls = enabled;
        direnv = enabled;
        fup-repl = enabled;
        git = enabled;
        glxinfo = enabled;
        lsd = enabled;
        nix-ld = enabled;
        oh-my-posh = enabled;
        spicetify-cli = enabled;
        topgrade = enabled;
      };

      hardware = {
        audio = enabled;
        networking = enabled;
        storage = enabled;
        power = enabled;
      };

      services = {
        printing = enabled;
        openssh = enabled;
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
        time = enabled;
        xkb = enabled;
      };
    };
  };
}
