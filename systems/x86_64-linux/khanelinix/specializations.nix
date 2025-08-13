{
  specialisation = {
    # NOTE: alternative kernel specialization
    # zen = {
    #   inheritParentConfig = true;
    #   configuration = {
    #     boot.kernelPackages = lib.mkForce pkgs.linuxPackages_zen;
    #   };
    # };
    #
    # NOTE: alternative kernel specialization
    # lts = {
    #   inheritParentConfig = true;
    #   configuration = {
    #     boot.kernelPackages = lib.mkForce pkgs.linuxPackages;
    #   };
    # };
  };
}
