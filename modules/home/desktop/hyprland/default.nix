{
  options,
  config,
  lib,
  inputs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.desktop.hyprland;
in {
  imports = with inputs; [
    hyprland.homeManagerModules.default
  ];

  options.khanelinix.desktop.hyprland = with types; {
    enable = mkEnableOption "Hyprland.";
  };

  config =
    mkIf cfg.enable
    {
      # start swayidle as part of hyprland, not sway
      systemd.user.services.swayidle.Install.WantedBy = lib.mkForce ["hyprland-session.target"];
      wayland.windowManager.hyprland.enable = true;
    };
}
