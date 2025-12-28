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
    environment.systemPackages = with pkgs; [ gnupg ];

    environment.shellInit = /* bash */ ''
      export GPG_TTY="$(tty)"
      export SSH_AUTH_SOCK=$(${getExe' pkgs.gnupg "gpgconf"} --list-dirs agent-ssh-socket)

      ${getExe' pkgs.coreutils "timeout"} ${toString cfg.agentTimeout} ${getExe' pkgs.gnupg "gpgconf"} --launch gpg-agent
      gpg_agent_timeout_status=$?

      if [ "$gpg_agent_timeout_status" = 124 ]; then
        # Command timed out...
        echo "GPG Agent timed out..."
        echo 'Run "gpgconf --launch gpg-agent" to try and launch it again.'
      fi
    '';

    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };

    khanelinix.home.file = {
      ".gnupg/.keep".text = "";
      ".gnupg/gpg-agent.conf".text = gpgAgentConf;
    };
  };
}
