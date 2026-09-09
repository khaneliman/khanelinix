{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.services.ananicy;
in
{
  options.khanelinix.services.ananicy = {
    enable = lib.mkEnableOption "Ananicy-cpp automatic process management";
  };

  config = mkIf cfg.enable {
    services.ananicy = {
      # Ananicy-cpp documentation
      # See: https://gitlab.com/ananicy-cpp/ananicy-cpp
      enable = true;
      package = pkgs.ananicy-cpp;
      # CachyOS rules are more aggressive and optimized for desktop performance
      rulesProvider = pkgs.ananicy-rules-cachyos;

      # The workaround moves every SCHED_RR process, including the compositor,
      # into the root cgroup to dodge RT_GROUP_SCHED. nixpkgs kernels build
      # without it, so the move only hides those processes from their session
      # scope and from cgroup memory policy.
      settings.cgroup_realtime_workaround = lib.mkForce false;
    };
  };
}
