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

  checkPhase = "";

  runtimeInputs = [ pciutils ];

  text = ''
    shopt -s nullglob

    for d in /sys/kernel/iommu_groups/*/devices/*; do
      n=''${d#*/iommu_groups/*}; n=''${n%%/*}
      printf 'IOMMU Group %s' "$n"
      lspci -nns "''${d##*/}"
    done
  '';
}
