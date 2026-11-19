{
  writeShellApplication,
  lib,
  pciutils,
  ...
}:
writeShellApplication {
  name = "list-iommu";

  meta = {
    mainProgram = "list-iommu";
    platforms = lib.platforms.linux;
  };

  passthru.updateScript = null;

  runtimeInputs = [ pciutils ];

  text = ''
    shopt -s nullglob

    for d in /sys/kernel/iommu_groups/*/devices/*; do
      group=''${d#/sys/kernel/iommu_groups/}
      group=''${group%%/*}
      printf 'IOMMU Group %s: ' "$group"
      lspci -nns "''${d##*/}"
    done
  '';
}
