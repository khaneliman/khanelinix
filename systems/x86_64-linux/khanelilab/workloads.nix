{ lib, ... }:
{
  # Historical services remain in their suites, but are not part of the
  # running AustinServer workload being migrated.
  services =
    lib.genAttrs
      [
        "adguardhome"
        "bazarr"
        "photoprism"
        "postgresql"
        "readarr"
        "vaultwarden"
      ]
      (_: {
        enable = lib.mkForce false;
      });

  virtualisation.oci-containers.containers =
    lib.genAttrs
      [
        "imagemaid"
        "maintainerr"
        "qdirstat"
        "stash"
        "tinymm-gui-v5"
        "yacht"
      ]
      (_: {
        autoStart = lib.mkForce false;
      });
}
