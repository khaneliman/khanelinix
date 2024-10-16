{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) concatStringsSep mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.services.earlyoom;
in
{
  options.${namespace}.services.earlyoom = {
    enable = mkBoolOpt false "Whether or not to configure oomd.";
  };

  config = mkIf cfg.enable {
    services.earlyoom = {
      enable = true;
      enableNotifications = true;

      reportInterval = 0;
      freeSwapThreshold = 5;
      freeSwapKillThreshold = 2;
      freeMemThreshold = 5;
      freeMemKillThreshold = 2;

      extraArgs =
        let
          appsToAvoid = concatStringsSep "|" [
            "(h|H)yprland"
            "(x|X)wayland"
            "bash"
            "cryptsetup"
            "dbus-.*"
            "foot"
            "gpg-agent"
            "greetd"
            "kitty"
            "n?vim"
            ".*qemu-system.*"
            "regreet"
            "sddm"
            "ssh-agent"
            "sshd"
            "sway"
            "systemd"
            "systemd-logind"
            "systemd-udevd"
            "tmux: client"
            "tmux: server"
            "wezterm"
            "zsh"
          ];

          appsToPrefer = concatStringsSep "|" [
            "Web Content"
            "Isolated Web Co"
            "chrom(e|ium).*"
            "dotnet"
            "firefox.*"
            ".firefox-wrappe"
            "electron"
            ".*.exe"
            "java"
            "nix"
            "npm"
            "node"
            "pipewire(.*)"
          ];
        in
        [
          "-g" # kill all processes within a process group
          "--avoid '^(${appsToAvoid})$'" # things we want to not kill
          "--prefer '^(${appsToPrefer})$'" # things we want to kill as soon as possible
        ];

      killHook = pkgs.writeShellScript "earlyoom-kill-hook" ''
        echo "Process $EARLYOOM_NAME ($EARLYOOM_PID) was killed"
      '';
    };

    systemd.services.earlyoom.serviceConfig = {
      # from upstream
      DynamicUser = true;
      AmbientCapabilities = "CAP_KILL CAP_IPC_LOCK";
      Nice = -20;
      OOMScoreAdjust = -100;
      ProtectSystem = "strict";
      ProtectHome = true;
      Restart = "always";
      TasksMax = 10;
      MemoryMax = "50M";

      # Protection rules. Mostly from the `systemd-oomd` service
      # with some of them already included upstream.
      CapabilityBoundingSet = "CAP_KILL CAP_IPC_LOCK";
      PrivateDevices = true;
      ProtectClock = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectControlGroups = true;
      RestrictNamespaces = true;
      RestrictRealtime = true;

      PrivateNetwork = true;
      IPAddressDeny = "any";
      RestrictAddressFamilies = "AF_UNIX";

      SystemCallArchitectures = "native";
      SystemCallFilter = [
        "@system-service"
        "~@resources @privileged"
      ];
    };
  };
}
