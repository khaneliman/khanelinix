{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib)
    types
    mkEnableOption
    mkIf
    getExe'
    ;
  inherit (lib.khanelinix) mkOpt;

  cfg = config.khanelinix.security.gpg;
  gpgPackage = config.programs.gnupg.package;

  gpgAgentConf = ''
    enable-ssh-support
    default-cache-ttl 60
    max-cache-ttl 120
  '';
in
{
  options.khanelinix.security.gpg = {
    enable = mkEnableOption "GPG";
    agentTimeout = mkOpt types.int 5 "The amount of time to wait before continuing with shell init.";
  };

  config = mkIf cfg.enable {
    environment.shellInit = /* bash */ ''
      if [ -t 0 ]; then
        export GPG_TTY="$(tty)"
      fi

      gpg_agent_status=0
      ${getExe' pkgs.coreutils "timeout"} ${toString cfg.agentTimeout} ${getExe' gpgPackage "gpgconf"} --launch gpg-agent || gpg_agent_status=$?
      if [ "$gpg_agent_status" = 124 ]; then
        echo "GPG Agent timed out..."
        echo 'Run "gpgconf --launch gpg-agent" to try and launch it again.'
      elif [ "$gpg_agent_status" = 0 ] && gpg_ssh_socket="$(${getExe' gpgPackage "gpgconf"} --list-dirs agent-ssh-socket)" && [ -n "$gpg_ssh_socket" ]; then
        if [ -z "''${SSH_AUTH_SOCK:-}" ]; then
          export SSH_AUTH_SOCK="$gpg_ssh_socket"
        fi
        if [ "$SSH_AUTH_SOCK" = "$gpg_ssh_socket" ] && [ -t 0 ]; then
          ${getExe' gpgPackage "gpg-connect-agent"} --quiet updatestartuptty /bye >/dev/null 2>&1
        fi
      fi
      unset gpg_agent_status gpg_ssh_socket
    '';

    programs.gnupg.agent = {
      enable = true;
      # nix-darwin's SSH integration overwrites inherited sockets in extraInit.
      # gpg-agent.conf enables SSH support; shellInit only selects the fallback.
      enableSSHSupport = lib.mkForce false;
    };
    launchd.user.agents.gnupg-agent.serviceConfig.RunAtLoad = lib.mkForce true;

    khanelinix.home.file = {
      ".gnupg/.keep".text = "";
      ".gnupg/gpg-agent.conf".text = gpgAgentConf;
    };
  };
}
