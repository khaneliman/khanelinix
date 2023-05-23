{ options
, config
, lib
, pkgs
, inputs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.desktop.addons.eww;

  dependencies = with pkgs; [
    bash
    blueberry
    bluez
    coreutils
    dbus
    findutils
    gawk
    gnome.gnome-control-center
    gnused
    imagemagick
    gojq
    jaq
    jc
    libnotify
    light
    networkmanager
    pavucontrol
    playerctl
    procps
    pulseaudio
    ripgrep
    socat
    udev
    upower
    util-linux
    wget
    wireplumber
    wlogout
  ];

  reload_script = pkgs.writeShellScript "reload_eww" ''
    windows=$(eww windows | rg '\*' | tr -d '*')

    systemctl --user restart eww.service

    echo $windows | while read -r w; do
      eww open $w
    done
  '';
in
{
  options.khanelinix.desktop.addons.eww = with types; {
    enable = mkBoolOpt false "Whether to enable eww in the desktop environment.";

    package = mkOpt package pkgs.eww-wayland "The Eww package to install";

    autoReload = mkBoolOpt false "Whether to restart the eww daemon and windows on change.";

    colors = lib.mkOption {
      type = with lib.types; nullOr lines;
      default = null;
      defaultText = lib.literalExpression "null";
      description = ''
        SCSS file with colors defined in the same way as Catppuccin colors are,
        to be used by eww.

        Defaults to Catppuccin Mocha.
      '';
    };
  };

  config = mkIf cfg.enable {

    environment.systemPackages = with pkgs; [

    ] ++ dependencies;

    fonts.fonts = with pkgs;
      [
        jost
        material-icons
        material-symbols
        material-design-icons
      ];

    khanelinix.home = {

      extraOptions = {

        # remove nix files
        xdg.configFile."eww" = {
          source = lib.cleanSourceWith {
            filter = name: _type:
              let
                baseName = baseNameOf (toString name);
              in
                !(lib.hasSuffix ".nix" baseName);
            src = lib.cleanSource ./.;
          };

          # links each file individually, which lets us insert the colors file separately
          recursive = true;

          onChange =
            if cfg.autoReload
            then reload_script.outPath
            else "";
        };

        home.packages = [
          cfg.package
        ];

        systemd.user.services.eww = {
          Unit = {
            Description = "Eww Daemon";
            # not yet implemented
            # PartOf = ["tray.target"];
            PartOf = [ "graphical-session.target" ];
          };
          Service = {
            Environment = "PATH=/run/wrappers/bin:${lib.makeBinPath dependencies}";
            ExecStart = "${cfg.package}/bin/eww daemon --no-daemonize";
            Restart = "on-failure";
          };
          Install.WantedBy = [ "graphical-session.target" ];
        };
      };
    };
  };
}
