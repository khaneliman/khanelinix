{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkDefault mkIf;

  cfg = config.khanelinix.hardware.tpm;
in
{
  options.khanelinix.hardware.tpm = {
    enable = lib.mkEnableOption "Trusted Platform Module 2 (TPM2)";
  };

  config = mkIf cfg.enable {
    security.tpm2 = {
      enable = true;

      # enable Trusted Platform 2 userspace resource manager daemon
      abrmd.enable = mkDefault false;

      # The TCTI is the "Transmission Interface" that is used to communicate with a
      # TPM. this option sets TCTI environment variables to the specified values if enabled
      #  - TPM2TOOLS_TCTI
      #  - TPM2_PKCS11_TCTI
      tctiEnvironment.enable = mkDefault true;

      # enable TPM2 PKCS#11 tool and shared library in system path
      pkcs11.enable = mkDefault false;
    };
  };
}
