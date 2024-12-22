{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.services.flatpak;
in
{
  options.${namespace}.services.flatpak = {
    enable = mkBoolOpt false "Whether or not to enable flatpak support.";
    extraRepos = lib.mkOption {
      default = [
        {
          name = "flathub";
          location = "https://flathub.org/repo/flathub.flatpakrepo";
        }
        {
          name = "flathub-beta";
          location = "https://flathub.org/beta-repo/flathub-beta.flatpakrepo";
        }
      ];
      type = lib.types.listOf (lib.types.attrsOf lib.types.str);
      description = "Extra flatpak repositories to add.";
    };
    extraPackages = lib.mkOption {
      default = [ ];
      type = lib.types.listOf (lib.types.either lib.types.str (lib.types.attrsOf lib.types.anything));
      description = "Flatpaks to install.";
      example = [
        {
          flatpakref = "https://sober.vinegarhq.org/sober.flatpakref";
          sha256 = "sha256:1pj8y1xhiwgbnhrr3yr3ybpfis9slrl73i0b1lc9q89vhip6ym2l";
        }
      ];
    };
  };

  config = mkIf cfg.enable {
    services.flatpak = {
      enable = true;

      remotes = cfg.extraRepos;
      packages = cfg.extraPackages;
    };
  };
}
