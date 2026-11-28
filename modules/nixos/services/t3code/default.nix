{
  config,
  lib,

  ...
}:
let
  cfg = config.khanelinix.services.t3code;

  inherit (config.users.users.${config.khanelinix.user.name}) uid;
  tailscaleEnabled = config.services.tailscale.enable;

  # Covers what the user manager hands on: 1536M for the server's slice and
  # 256M for the manager itself.
  userChainLow = "2G";
  # Near the floor, yet unlike -1000 the kernel can still kill it as a last
  # resort.
  protectedOomScore = -900;
in
{
  options.khanelinix.services.t3code.protect.enable =
    lib.mkEnableOption "memory protection for the T3 Code user server";

  # The declarative form of `t3 service protect`, which writes drop-ins under
  # /etc/systemd/system and so cannot run on NixOS. The Home Manager module
  # sets the user manager's half when this is enabled.
  config = lib.mkIf cfg.protect.enable {
    assertions = [
      {
        # A null uid would name the templates and protect every user.
        assertion = uid != null;
        message = "khanelinix.services.t3code.protect needs a fixed uid for ${config.khanelinix.user.name}";
      }
    ];

    systemd = {
      # Protection reaches the server only when every ancestor cgroup grants
      # it, and only root can grant it down to the user manager.
      slices = {
        user.sliceConfig.MemoryLow = userChainLow;
        "user-${toString uid}" = {
          overrideStrategy = "asDropin";
          sliceConfig.MemoryLow = userChainLow;
        };
        system.sliceConfig.MemoryLow = lib.mkIf tailscaleEnabled "512M";
      };

      services = {
        "user@${toString uid}" = {
          overrideStrategy = "asDropin";
          # Keep the template's PATH, and never restart the manager on a
          # switch: that ends the user's session.
          enableDefaultPath = false;
          restartIfChanged = false;
          serviceConfig = {
            MemoryLow = userChainLow;
            # A user service cannot score below its manager.
            OOMScoreAdjust = protectedOomScore;
          };
        };
        # Remote clients reach the server through Tailscale Serve. sshd is
        # socket-activated on these hosts and has no long-running unit; a host
        # that runs it as a service should protect it here too.
        tailscaled.serviceConfig = lib.mkIf tailscaleEnabled {
          MemoryLow = "256M";
          OOMScoreAdjust = protectedOomScore;
        };
      };

      # A user manager hands its services its own score plus 100, so without
      # this every user service would run at -800.
      user.settings.Manager.DefaultOOMScoreAdjust = 200;
    };
  };
}
