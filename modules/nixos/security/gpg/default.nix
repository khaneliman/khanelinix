{ config
, lib
, options
, pkgs
, inputs
, ...
}:
let
  inherit (lib) types mkIf getExe getExe';
  inherit (lib.internal) mkBoolOpt mkOpt;
  inherit (inputs) gpg-base-conf yubikey-guide;

  cfg = config.khanelinix.security.gpg;

  gpgConf = "${gpg-base-conf}/gpg.conf";

  gpgAgentConf = ''
    enable-ssh-support
    default-cache-ttl 60
    max-cache-ttl 120
    pinentry-program ${getExe pkgs.pinentry-gnome}
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

  guideDesktopItem = pkgs.makeDesktopItem {
    categories = [ "System" ];
    desktopName = "Yubikey Guide";
    exec = "${getExe' pkgs.xdg-utils "xdg-open"} ${guideHTML}";
    genericName = "View Yubikey Guide in a web browser";
    icon = ./yubico-icon.svg;
    name = "yubikey-guide";
  };

  reload-yubikey = pkgs.writeShellScriptBin "reload-yubikey" ''
    ${getExe' pkgs.gnupg "gpg-connect-agent"} "scd serialno" "learn --force" /bye
  '';
in
{
  options.khanelinix.security.gpg = with types; {
    enable = mkBoolOpt false "Whether or not to enable GPG.";
    agentTimeout = mkOpt int 5 "The amount of time to wait before continuing with shell init.";
  };

  config = mkIf cfg.enable {
    environment.shellInit = ''
      ${getExe' pkgs.coreutils "timeout"} ${builtins.toString cfg.agentTimeout} ${getExe' pkgs.gnupg "gpgconf"} --launch gpg-agent
      gpg_agent_timeout_status=$?

      if [ "$gpg_agent_timeout_status" = 124 ]; then
        # Command timed out...
        echo "GPG Agent timed out..."
        echo 'Run "gpgconf --launch gpg-agent" to try and launch it again.'
      fi
    '';

    environment.systemPackages = with pkgs; [
      cryptsetup
      gnupg
      guideDesktopItem
      paperkey
      paperkey
      pinentry-curses
      pinentry-qt
      reload-yubikey
    ];

    khanelinix = {
      home.file = {
        ".gnupg/yubikey-guide.md".source = guide;
        ".gnupg/yubikey-guide.html".source = guideHTML;

        ".gnupg/gpg.conf".source = gpgConf;
        ".gnupg/gpg-agent.conf".text = gpgAgentConf;
      };
    };

    programs = {
      ssh.startAgent = false;

      gnupg.agent = {
        enable = true;
        enableExtraSocket = true;
        enableSSHSupport = true;
        pinentryFlavor = "gnome3";
      };
    };

    services = {
      pcscd.enable = true;
      udev.packages = with pkgs; [ yubikey-personalization ];
    };
  };
}
