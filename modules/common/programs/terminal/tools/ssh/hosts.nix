# Static host metadata for SSH configuration
# This replaces the dynamic cross-configuration evaluation that caused multiple evaluations
{
  # NixOS hosts
  bruddynix = {
    hostname = "bruddynix.local";
    username = "bruddy";
    system = "nixos";
    gpgAgent = true;
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFeLt5cnRnKeil39Ds+CimMJQq/5dln32YqQ+EfYSCvc";
    userPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEqCiZgjOmhsBTAFD0LbuwpfeuCnwXwMl2wByxC1UiRt";
  };

  khanelinix = {
    hostname = "khanelinix.local";
    username = "khaneliman";
    system = "nixos";
    gpgAgent = true;
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKEilFPAgSUwW3N7PTvdTqjaV2MD3cY2oZGKdaS7ndKB";
    userPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFuMXeT21L3wnxnuzl0rKuE5+8inPSi8ca/Y3ll4s9pC";
  };

  khanelilab = {
    hostname = "khanelilab.local";
    username = "khaneliman";
    system = "nixos";
    gpgAgent = true;
  };

  # Darwin hosts
  khanelimac = {
    hostname = "khanelimac.local";
    username = "khaneliman";
    system = "darwin";
    gpgAgent = true;
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJAZIwy7nkz8CZYR/ZTSNr+7lRBW2AYy1jw06b44zaID";
    userPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINBG8l3jQ2EPLU+BlgtaQZpr4xr97n2buTLAZTxKHSsD";
  };

  "khanelimac-m1" = {
    hostname = "khanelimac-m1.local";
    username = "khaneliman";
    system = "darwin";
    gpgAgent = true;
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAJX6b2buv6PO/J8fWuMpUEM/snSuJd7FtWLTUHiWgna";
    userPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGFA599aGAr1pFCo3SjDx4NlFh4o468CTrUwFDs9VPX2";
  };
}
