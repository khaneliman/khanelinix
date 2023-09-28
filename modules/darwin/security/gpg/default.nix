{ config
, lib
, pkgs
, inputs
, ...
}:
let
  inherit (lib) types mkEnableOption mkIf getExe getExe';
  inherit (lib.internal) mkOpt;
  inherit (inputs) gpg-base-conf yubikey-guide;

  cfg = config.khanelinix.security.gpg;

  gpgConf = "${gpg-base-conf}/gpg.conf";

  gpgAgentConf = ''
    enable-ssh-support
    default-cache-ttl 60
    max-cache-ttl 120
  '';

  guide = "${yubikey-guide}/README.md";

  theme = pkgs.fetchFromGitHub {
    owner = "jez";
    repo = "pandoc-markdown-css-theme";
    rev = "019a4829242937761949274916022e9861ed0627";
    sha256 = "1h48yqffpaz437f3c9hfryf23r95rr319lrb3y79kxpxbc9hihxb";
  };

  guideHTML = pkgs.runCommand "yubikey-guide" { } ''
    ${getExe pkgs.pandoc} \
      --standalone \
      --metadata title="Yubikey Guide" \
      --from markdown \
      --to html5+smart \
      --toc \
      --template ${theme}/template.html5 \
      --css ${theme}/docs/css/theme.css \
      --css ${theme}/docs/css/skylighting-solarized-theme.css \
      -o $out \
      ${guide}
  '';
in
{
  options.khanelinix.security.gpg = {
    enable = mkEnableOption "GPG";
    agentTimeout = mkOpt types.int 5 "The amount of time to wait before continuing with shell init.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      gnupg
    ];

    environment.shellInit = ''
      export GPG_TTY="$(tty)"
      export SSH_AUTH_SOCK=$(${getExe' pkgs.gnupg "gpgconf"} --list-dirs agent-ssh-socket)

      ${getExe' pkgs.coreutils "timeout"} ${builtins.toString cfg.agentTimeout} ${getExe' pkgs.gnupg "gpgconf"} --launch gpg-agent
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

      ".gnupg/yubikey-guide.md".source = guide;
      ".gnupg/yubikey-guide.html".source = guideHTML;

      ".gnupg/gpg.conf".source = gpgConf;
      ".gnupg/gpg-agent.conf".text = gpgAgentConf;
    };
  };
}
