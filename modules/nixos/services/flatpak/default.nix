{
  config,
  lib,
  namespace,
  pkgs,
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
      default = {
        flathub = "https://flathub.org/repo/flathub.flatpakrepo";
      };
      type = lib.types.attrsOf lib.types.str;
      description = "Extra flatpak repositories to add.";
    };
  };

  config = mkIf cfg.enable {
    services.flatpak.enable = true;
    systemd.services.flatpak-repos = {
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.flatpak ];
      script =
        let
          generateRepoScript =
            repos:
            lib.concatStringsSep "\n" (
              lib.mapAttrsToList (name: url: ''
                flatpak remote-add --if-not-exists ${name} ${url}
              '') repos
            );
        in
        generateRepoScript cfg.extraRepos;
    };
  };
}
