{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.suites.common-slim;
in
{
  options.khanelinix.suites.common-slim = with types; {
    enable = mkBoolOpt false "Whether or not to enable common-slim configuration.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      khanelinix.list-iommu
      snowfallorg.flake
      exa
      fd
      wget
      curl
      socat
      xclip
      killall
      unzip
      file
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
        direnv = enabled;
        fup-repl = enabled;
        git = enabled;
        lsd = enabled;
      };

      hardware = {
        networking = enabled;
        storage = enabled;
      };

      services = {
        openssh = enabled;
        tailscale = enabled;
      };

      security = {
        doas = enabled;
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
