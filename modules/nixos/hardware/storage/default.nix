{ options
, config
, pkgs
, lib
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.hardware.storage;
in
{
  options.khanelinix.hardware.storage = with types; {
    enable =
      mkBoolOpt false
        "Whether or not to enable support for extra storage devices.";
    btrfs = mkBoolOpt false "Whether to enable btrfs extra software;";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      ntfs3g
      fuseiso
      nfs-utils
      btrfs-progs
    ] ++ lib.optionals cfg.btrfs [
      btdu
      btrfs-snap
      compsize
      # dduper
      snapper
    ];
  };
}
