{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf getExe' stringAfter;
  inherit (lib.khanelinix) enabled;

  cfg = config.khanelinix.display-managers.sddm;

  userName = config.khanelinix.user.name;

  themePackage = pkgs.catppuccin-sddm-corners;

  # SDDM only prefills the username from state written after a successful
  # login; seed it so the very first login is already populated.
  seedStateFile = pkgs.writeText "sddm-state.conf" ''
    [Last]
    User=${userName}
  '';
in
{
  options.khanelinix.display-managers.sddm = {
    enable = lib.mkEnableOption "sddm";
  };

  config = mkIf cfg.enable {
    khanelinix.home.configFile =
      let
        inherit (config.home-manager.users.${userName}.khanelinix.user) icon;
      in
      lib.mkIf (icon != null) {
        "sddm/faces/.${userName}".source = icon;
      };

    services = {
      displayManager = {
        sddm = {
          # SDDM documentation
          # See: https://github.com/sddm/sddm
          inherit (cfg) enable;
          # package = pkgs.libsForQt5.sddm;
          # TODO: update theme support
          # mkDefault so desktop environments (plasma6) can provide their own wrapped sddm
          package = lib.mkDefault pkgs.kdePackages.sddm;
          theme = "${themePackage}/share/sddm/themes/catppuccin-sddm-corners";
          wayland = enabled;

          extraPackages = [
            themePackage
          ];
        };
      };
    };

    # C = copy only when the destination is missing, so SDDM's own last-user
    # tracking still wins after the first login (C+ would force it every boot)
    systemd.tmpfiles.rules = [
      "C /var/lib/sddm/state.conf 0600 sddm sddm - ${seedStateFile}"
    ];

    system.activationScripts.postInstallSddm = stringAfter [ "users" ] /* Bash */ ''
      echo "Setting sddm permissions for user icon"
      ${getExe' pkgs.acl "setfacl"} -m u:sddm:x /home/${userName}
    '';
  };
}
