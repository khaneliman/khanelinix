{ writeShellApplication
, pciutils
, ...
}:
writeShellApplication
{
  name = "list-iommu";

  meta = {
    mainProgram = "list-iommu";
  };

  checkPhase = "";

  runtimeInputs = [
    pciutils
  ];

  text = /* bash */ ''
    shopt -s nullglob

    for d in /sys/kernel/iommu_groups/*/devices/*; do
      n=''${d#*/iommu_groups/*}; n=''${n%%/*}
      printf 'IOMMU Group %s' "$n"
      lspci -nns "''${d##*/}"
    done
  '';
}
