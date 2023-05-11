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
  options.khanelinix.suites.common = with types; {
    enable = mkBoolOpt false "Whether or not to enable common configuration.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.khanelinix.list-iommu
    ];

    khanelinix = {
      nix = enabled;

      cli-apps = {
        btop = enabled;
        fastfetch = enabled;
        feh = enabled;
        flake = enabled;
        glow = enabled;
        ranger = enabled;
      };

      tools = {
        atool = enabled;
        bat = enabled;
        bottom = enabled;
        comma = enabled;
        direnv = enabled;
        exa = enabled;
        fup-repl = enabled;
        git = enabled;
        lsd = enabled;
        misc = enabled;
        nix-ld = enabled;
        oh-my-posh = enabled;
        socat = enabled;
        spicetify-cli = enabled;
        toilet = enabled;
        topgrade = enabled;
        xclip = enabled;
      };

      hardware = {
        audio = enabled;
        networking = enabled;
        storage = enabled;
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
